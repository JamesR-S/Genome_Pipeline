process GLNEXUS {
    container 'docker://cgrlab/glnexus:v1.4.1'
    tag "${family}"
    cpus 16
    publishDir "${params.batchDir}/r04_vcfs", mode: 'copy', overwrite: true, failOnError: true
    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(gvcfs), file(gvcfcsis)

    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${family}.vcf.gz"), file("${family}.vcf.gz.csi")

    script:
    """
    mkdir -p \$PWD/temp
    export TMPDIR=\$PWD/temp
    glnexus_cli --config DeepVariant ${gvcfs.join(" ")} > ${family}.bcf

    bcftools view ${family}.bcf | bgzip -@ 4 -c > ${family}.vcf.gz

    bcftools index ${family}.vcf.gz
    """
}
