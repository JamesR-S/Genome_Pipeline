#!/usr/bin/env nextflow
process bwaMem {
    tag "${sample.name}"
    publishDir "r03_assembly", mode: 'copy'
    input:
      val sample
    output:
      tuple val(sample.name), file("${sample.name}.sam")
    script:
      """
      echo "Running bwa mem for sample ${sample.name}"
      ${params.bwa} mem -t 16 -M -R "@RG\\tID:${sample.flowcell}\\tPL:${sample.platform}\\tSM:${sample.name}\\tLB:${sample.name}_${sample.flowcell}" \
      ${params.referenceFasta} fastq/${sample.fastq1} fastq/${sample.fastq2} > ${sample.name}.sam
      """
}
