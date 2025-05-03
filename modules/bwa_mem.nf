#!/usr/bin/env nextflow
process BWA_MEM {
    cpus 16
    tag "${id}"
    stageInMode 'copy'
    input:
      tuple val(id), val(platform), val(sex), val(family), val(trio), val(flowcell), val(laneCount), val(famSampleCount), file(fastq1), file(fastq2)
    output:
      tuple val(id), val(sex), val(family), val(trio), val(laneCount), val(famSampleCount),file("${id}_${flowcell}.sam")
    script:
      """
      echo "Running bwa mem for sample ${id}"
      ${params.bwa} mem -t 16 -M -R "@RG\\tID:${flowcell}\\tPL:${platform}\\tSM:${id}\\tLB:${id}_${flowcell}" \
         ${params.referenceFasta} ${fastq1} ${fastq2} > ${id}_${flowcell}.sam
      """
}
