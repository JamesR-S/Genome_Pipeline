#!/usr/bin/env nextflow
process VCF_FILTER {
    tag "${family}"
    module 'BCFtools/1.17-GCC-12.2.0'
    publishDir "r04_vcfs", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(vcf), file(csi)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${family}_filtered.vcf.gz"), file("${family}_filtered.vcf.gz.csi")
    script:
      """
      bcftools isec -C -w1 -Ou ${vcf} ${params.gnomadSNP} | bcftools view -f PASS  -Oz -o ${family}_filtered.vcf.gz
      bcftools index ${family}_filtered.vcf.gz
      """
}