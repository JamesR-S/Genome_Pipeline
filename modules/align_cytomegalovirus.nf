#!/usr/bin/env nextflow
process ALIGN_CYTOMEGALOVIRUS {
    cpus 16
    tag "${id}"
    publishDir "${params.batchDir}/r04_cytomegalovirus", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(fastq)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount),file("${id}_cytomegalovirus_grepped2.sam")
    script:
      """
      ${params.bwaMem2} mem -t 16 -M  ${params.cytomegaloFasta} ${fastq} > ${id}_cytomegalovirus.sam

      grep '^@\\|NC_006273\\.2' ${id}_cytomegalovirus.sam > ${id}_cytomegalovirus_grepped2.sam
      """
}
