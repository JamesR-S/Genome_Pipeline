process DEEP_VARIANT {
    tag "${id}"
    container 'google/deepvariant:1.8.0'
    
    publishDir(
        path: { "r03_vcfs" },
        pattern: "*.vcf.gz",
        mode: 'copy')

    publishDir(
        path: { "r03_gvcfs" },
        pattern: "*.g.vcf.gz",
        mode: 'copy')
    
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(bam), file(bai)
    output:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file("${id}.g.vcf.gz"), file("${id}.vcf.gz")
    script:
      """
      /opt/deepvariant/bin/run_deepvariant \
        --model_type=WGS \
        --ref=${params.referenceFasta} \
        --reads=${bam} \
        --output_gvcf=${id}.g.vcf.gz \
        --output_vcf=${id}.vcf.gz \
        --num_shards=16
        --vcf_stats_report=true
      """
}