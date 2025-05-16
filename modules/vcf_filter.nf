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
      | bcftools +setGT -Ou -- -t q  -n . \
      -i 'FMT/DP<8 || FMT/GQ<20 || (GT="0/1" && (FMT/VAF<0.2 || FMT/VAF>0.8))' \
      | bcftools filter -s LowQualDepth \
      -e 'QUAL<10 || N_PASS(GT!="mis")==0' -Ou \
      | bcftools view -f PASS -Oz -o ${family}_filtered.vcf.gz

      bcftools index ${family}_filtered.vcf.gz
      """
}