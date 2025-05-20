#!/usr/bin/env nextflow
process RELATEDNESS {
    tag { id.join('-') }
    module 'VCFtools/0.1.16-GCC-11.2.0'
    cpus 1
    publishDir "${params.batchDir}/r04_metrics", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(vcf), file(csi)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("relatedness2.csv")
    script:
      """
      vcfs=( ${vcf.join(" ")} )
      for i in \${vcfs[@]}; do
           tabix -p vcf \${i} ;
           vcftools --relatedness2 -c --vcf \${i} >> relatedness2.csv
      done    
      """
}