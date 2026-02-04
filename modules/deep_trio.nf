process DEEP_TRIO {
    tag { trio_ids.join('-') }
    // queue 'pq'
    time '1d 12h'
    cpus 16
    container 'docker://google/deepvariant:deeptrio-1.9.0'
    containerOptions('-B /usr/lib/locale/:/usr/lib/locale/')
    
    publishDir "${params.batchDir}/r04_deep_trio", mode: 'copy'
    
    input:
      tuple val(id), val(sex), val(trio_ids), file(bam), file(bai)
      file(Fasta)
      file(Fai)
    output:
      tuple val(id), val(sex), val(trio_ids), file("*_proband.vcf.gz"),file("*_father.vcf.gz"),file("*_mother.vcf.gz"), file("*_proband.vcf.gz.tbi"),file("*_father.vcf.gz.tbi"),file("*_mother.vcf.gz.tbi")
    script:
      """
      mkdir -p \$PWD/temp
      export TMPDIR=\$PWD/temp
      /opt/deepvariant/bin/deeptrio/run_deeptrio \
        --model_type=WGS \
        --ref=${Fasta[0]} \
        --reads_child=${bam[0]} \
        --reads_parent1=${bam[1]} \
        --reads_parent2=${bam[2]} \
        --output_vcf_child \$(basename ${bam[0]} .bam)_proband.vcf.gz \
        --output_vcf_parent1 \$(basename ${bam[1]} .bam)_father.vcf.gz \
        --output_vcf_parent2 \$(basename ${bam[2]} .bam)_mother.vcf.gz \
        --output_gvcf_child \$(basename ${bam[0]} .bam)_proband.g.vcf.gz \
        --output_gvcf_parent1 \$(basename ${bam[1]} .bam)_father.g.vcf.gz \
        --output_gvcf_parent2 \$(basename ${bam[2]} .bam)_mother.g.vcf.gz \
        --sample_name_child "\$(basename ${bam[0]} .bam)" \
        --sample_name_parent1 "\$(basename ${bam[1]} .bam)" \
        --sample_name_parent2 "\$(basename ${bam[2]} .bam)" \
        --num_shards ${task.cpus}  \
        --intermediate_results_dir intermediate_results_dir \
        --regions "chr1 chr2 chr3 chr4 chr5 chr6 chr7 chr8 chr9 chr10 chr11 chr12 chr13 chr14 chr15 chr16 chr17 chr18 chr19 chr20 chr21 chr22 chrX chrY"
      """
}

process FILTER_DENOVO {
  tag { trio_ids.join('-') }
  publishDir "${params.batchDir}/r04_deep_trio", mode: 'copy'
  cpus 16
    input:
    tuple val(id), val(sex), val(trio_ids), file(proband_vcfs), file(father_vcfs), file(mother_vcfs), file(proband_vcfscis), file(father_vcfscis), file(mother_vcfscis)
    
    output:
    file("*_denovo.vcf.gz")

    script:
    """
    ${params.rtgtools} vcfmerge ${father_vcfs} ${mother_vcfs} ${proband_vcfs} \
      --add-header "##PEDIGREE=<Child=${trio_ids[0]},Mother=${trio_ids[2]},Father=${trio_ids[1]}>" \
      --add-header "##SAMPLE=<ID=${trio_ids[0]},Sex=\$(echo ${sex[0]} | tr '[a-z]' '[A-Z]')>" \
      --output ${trio_ids.join("-")}_trio.vcf.gz

    ${params.rtgtools} mendelian -t /path/to/ref.sdf --input ${trio_ids.join("-")}_trio.vcf.gz \
      --lenient --output-inconsistent ${trio_ids.join("-")}_denovo.vcf.gz
    """
}