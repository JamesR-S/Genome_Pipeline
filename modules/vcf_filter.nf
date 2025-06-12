#!/usr/bin/env nextflow
process VCF_FILTER {
    tag "${family}"
    cpus 4
    module 'BCFtools/1.17-GCC-12.2.0'
    publishDir "${params.batchDir}/r04_vcfs", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(vcf), file(csi)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${family}_filtered.vcf.gz"), file("${family}_filtered.vcf.gz.csi")
    script:
      """
      bcftools view -Ov -o ${family}.vcf ${vcf}
      java -Xmx5g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -cp ${params.javaDir} FilterVcfDiscordance ${family}.vcf ${params.gnomadSNPFilter} \
      | bcftools +fill-tags -Ou -- -t FORMAT/VAF \
      | bcftools view -Oz -o ${family}_filtered.vcf.gz

      bcftools index ${family}_filtered.vcf.gz
      """
}