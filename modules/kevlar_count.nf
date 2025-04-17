#!/usr/bin/env nextflow
process kevlarCount {
    tag "${sample.name}"
    publishDir "r04_kevlar", mode: 'copy'
    input:
      tuple val(sample), file(checkFile)
    output:
      tuple val(sample.name), file("${sample.name}.ct")
    script:
      """
      echo "Running kevlar count for sample ${sample.name}"
      kevlar count --memory 70000M --mask ${params.kevlarMask} fastq/${sample.fastq1} fastq/${sample.fastq2} > ${sample.name}.ct
      """
}
