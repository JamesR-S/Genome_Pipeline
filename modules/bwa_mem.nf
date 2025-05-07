#!/usr/bin/env nextflow
process BWA_MEM {
    cpus 16
    tag "${id}"
    stageInMode 'copy'
    module 'SAMtools/1.17-GCC-12.2.0'

    input:
      tuple val(id), val(platform), val(sex), val(family), val(trio),
            val(flowcell), val(laneCount), val(famSampleCount),
            file(fastq1), file(fastq2)

    output:
      tuple val(id), val(sex), val(family), val(trio),
            val(laneCount), val(famSampleCount),
            file("${id}_${flowcell}_ns.bam")

    script:
      """
      set -euo pipefail
      echo "[${id}|${flowcell}] bwa-mem2 → name-sorted BAM"
      ${params.bwa} mem -t ${task.cpus} -M \
        -R "@RG\\tID:${flowcell}\\tPL:${platform}\\tSM:${id}\\tLB:${id}_${flowcell}" \
        ${params.referenceFasta} ${fastq1} ${fastq2} \
      | samtools view   -u -@ ${task.cpus} -                \\
      | samtools sort   -n -@ ${task.cpus} -l 1 -o ${id}_${flowcell}_ns.bam
      """
}
