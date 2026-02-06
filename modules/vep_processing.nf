process VEP_PROCESSING {
    tag "${family}"
    module 'BCFtools/1.17-GCC-12.2.0'
    publishDir "${params.batchDir}/r04_vep", mode: 'copy', overwrite: true, failOnError: true
    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(vcf)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${family}_vep_annotated.vcf.gz"), file("${family}_vep_annotated.vcf.gz.csi")
    script:
      """
      bcftools view -Oz -o ${family}_vep_annotated.vcf.gz ${vcf}
      bcftools index ${family}_vep_annotated.vcf.gz

      """
}