process GLNEXUS {
    container 'quay.io/mlin/glnexus:v1.4.1'
    tag "${family}"
    publishDir "r04_vcfs", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(gvcfs), file(gvcfcsis)

    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${family}.vcf.gz"), file("${family}.vcf.gz.csi")

    script:
    """
    glnexus_cli --config DeepVariant ${gvcfs.join(" ")} > ${family}.bcf

    bcftools view ${family}.bcf | bgzip -@ 4 -c > ${family}.vcf.gz

    bcftools index ${family}.vcf.gz
    """
}
