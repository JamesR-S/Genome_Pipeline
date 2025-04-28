process DEEP_TRIO {
    tag { trio_ids.join('-') }
    cpus 16
    container 'docker://google/deepvariant:deeptrio-1.8.0'
    containerOptions('-B /usr/lib/locale/:/usr/lib/locale/')
    
    publishDir "r04_deep_trio", mode: 'copy'
    
    input:
      tuple val(id), val(sex), val(trio_ids), file(bam), file(bai)
      file(Fasta)
      file(Fai)
    output:
      tuple val(id), val(sex), val(trio_ids), file("*_proband.vcf.gz"),file("*_father.vcf.gz"),file("*_mother.vcf.gz"), file("*_proband.vcf.gz.csi"),file("*_father.vcf.gz.csi"),file("*_mother.vcf.gz.csi")
    script:
      """
      /opt/deepvariant/bin/deeptrio/run_deeptrio \
        --model_type=WGS \
        --ref=${Fasta[0]} \
        --reads_child=${bam[0]} \
        --reads_parent1=${bam[1]} \
        --reads_parent2=${bam[2]} \
        --output_vcf_child \$(basename ${bam[0]})_proband.vcf.gz \
        --output_vcf_parent1 \$(basename ${bam[1]})_father.vcf.gz \
        --output_vcf_parent2 \$(basename ${bam[2]})_mother.vcf.gz \
        --sample_name_child "\$(basename ${bam[0]})" \
        --sample_name_parent1 "\$(basename ${bam[1]})" \
        --sample_name_parent2 "\$(basename ${bam[2]})" \
        --num_shards 16  \
        --intermediate_results_dir intermediate_results_dir \
        --output_gvcf_child \$(basename ${bam[0]})_proband.g.vcf.gz \
        --output_gvcf_parent1 \$(basename ${bam[1]})_father.g.vcf.gz \
        --output_gvcf_parent2 \$(basename ${bam[2]})_mother.g.vcf.gz

        bcftools index \$(basename ${bam[0]}).vcf.gz
        bcftools index \$(basename ${bam[1]}).vcf.gz
        bcftools index \$(basename ${bam[2]}).vcf.gz
      """
}

process DEEP_TRIO_DENOVO {
  tag { trio_ids.join('-') }
  cpus 16
    input:
    tuple val(id), val(sex), val(trio_ids), file(proband_vcfs), file(father_vcfs), file(mother_vcfs), file(proband_vcfscis), file(father_vcfscis), file(mother_vcfscis)
    
    output:
    file("*_denovo.vcf.gz")

    script:
    """
    ${params.rtgtools} vcfmerge ${father_vcfs} ${mother_vcfs} ${proband_vcfs} \
      --add-header "##PEDIGREE=<Child=${trio_ids[0]},Mother=${trio_ids[2]},Father=${trio_ids[1]}>" \
      --add-header "##SAMPLE<ID=${trio_ids[0]},Sex-${sex[0]}>" \
      --output ${trio_ids.join("-")}_trio.vcf.gz

    ${params.rtgtools} mendelian -t /path/to/ref.sdf --input ${trio_ids.join("-")}_trio.vcf.gz \
      --lenient --output-inconsistent ${trio_ids.join("-")}_denovo.vcf.gz
    """
}