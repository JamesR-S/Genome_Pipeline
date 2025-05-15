process DV_VCF_PROCESSING {
    tag "${family}"
    module 'BCFtools/1.17-GCC-12.2.0'
    publishDir("${params.batchDir}/r04_vcfs", mode: 'copy')
    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(vcf)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${id}.vcf.gz"), file("${id}.vcf.gz.csi")
    script:
      """
      bcftools view -Oz -o ${id}.vcf.gz ${vcf}
      bcftools index ${id}.vcf.gz

      """
}

process DV_GVCF_PROCESSING {
    tag "${family}"
    module 'BCFtools/1.17-GCC-12.2.0'
    stageInMode 'copy'
    publishDir("${params.batchDir}/r04_gvcfs", mode: 'copy')
    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(gvcf)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${id}.g.vcf.gz"), file("${id}.g.vcf.gz.csi")
    script:
      """
      bcftools index ${gvcf}
      """
}