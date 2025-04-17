process DEEP_TRIO {
    tag "${trio_ids.join("-")}"
    container 'google/deepvariant:deeptrio-1.8.0'
    
    publishDir "r03_deep_trio", mode: 'copy'
    
    input:
      tuple val(id), val(sex), val(trio_ids), file(bam), file(bai)
      file(Fasta)
    output:
      tuple val(id), val(sex), val(trio_ids), [file("${trio_ids[0]}.vcf.gz"),file("${trio_ids[1]}.vcf.gz"),file("${trio_ids[2]}.vcf.gz")], [file("${trio_ids[0]}.vcf.gz.csi"),file("${trio_ids[1]}.vcf.gz.csi"),file("${trio_ids[2]}.vcf.gz.csi")]
    script:
      """
      /opt/deepvariant/bin/deeptrio/run_deeptrio \
        --model_type=WGS \
        --ref=${Fasta} \
        --reads_child=${bam[0]} \
        --reads_parent1=${bam[1]} \
        --reads_parent2=${bam[2]} \
        --output_vcf_child \$(basename ${bam[0]}).vcf.gz \
        --output_vcf_parent1 \$(basename ${bam[1]}).vcf.gz \
        --output_vcf_parent2 \$(basename ${bam[2]}).vcf.gz \
        --sample_name_child "\$(basename ${bam[0]})" \
        --sample_name_parent1 "\$(basename ${bam[1]})" \
        --sample_name_parent2 "\$(basename ${bam[2]})" \
        --num_shards $(nproc)  \
        --intermediate_results_dir intermediate_results_dir \
        --output_gvcf_child \$(basename ${bam[0]}).g.vcf.gz \
        --output_gvcf_parent1 \$(basename ${bam[1]}).g.vcf.gz \
        --output_gvcf_parent2 \$(basename ${bam[2]}).g.vcf.gz

        bcftools index \$(basename ${bam[0]}).vcf.gz
        bcftools index \$(basename ${bam[1]}).vcf.gz
        bcftools index \$(basename ${bam[2]}).vcf.gz
      """
}

process DEEP_TRIO_DENOVO {
  tag "${trio_ids.join("-")}"
    input:
    tuple val(id), val(sex), val(trio_ids), file(vcfs), file(vcfcsis)
    
    output:
    file("${trio_ids.join("-")}_denovo.vcf.gz")

    script:
    """
    ${params.rtgtools} vcfmerge ${vcfs[1]} ${vcfs[2]} ${vcfs[0]} \
      --add-header "##PEDIGREE=<Child=${trio_ids[0]},Mother=${trio_ids[2]},Father=${trio_ids[1]}>" \
      --add-header "##SAMPLE<ID=${trio_ids[0]},Sex-${sex[0]}>" \
      --output ${trio_ids.join("-")}_trio.vcf.gz

    ${params.rtgtools} mendelian -t /path/to/ref.sdf --input ${trio_ids.join("-")}_trio.vcf.gz \
      --lenient --output-inconsistent ${trio_ids.join("-")}_denovo.vcf.gz
    """
}