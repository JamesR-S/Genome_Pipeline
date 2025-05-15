process DEEP_VARIANT {
    tag "${id}"
    cpus 16
    container 'docker://google/deepvariant:1.9.0'
    containerOptions('-B /usr/lib/locale/:/usr/lib/locale/')
    publishDir(
        path: { "${params.batchDir}/r04_vcfs" },
        pattern: ['regex:.*(?<!\\.g)\\.vcf\\.gz$','regex:.*(?<!\\.g)\\.vcf\\.gz\\.csi$'],
        mode: 'copy')

    publishDir(
        path: { "${params.batchDir}/r04_gvcfs" },
        pattern: ["*.g.vcf.gz"],["*.g.vcf.gz.csi"],
        mode: 'copy')
    
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(bam), file(bai)
      file(Fasta)
      file(Fai)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${id}.g.vcf.gz"), file("${id}.g.vcf.gz.csi"), emit: gvcf 
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${id}.vcf.gz"), file("${id}.vcf.gz.csi"), emit: vcf
    script:
      """
      /opt/deepvariant/bin/run_deepvariant \
        --model_type=WGS \
        --ref=${Fasta[0]} \
        --reads=${bam} \
        --output_gvcf=${id}.g.vcf.gz \
        --output_vcf=${id}.vcf.gz \
        --num_shards=16 \
        --vcf_stats_report=true

        bcftools index ${id}.g.vcf.gz
        bcftools index ${id}.vcf.gz
      """
}