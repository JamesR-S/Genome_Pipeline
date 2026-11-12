#!/usr/bin/env nextflow
process FIXMATE {
    cpus 16
    container 'mgibio/samtools:v1.24'
    tag "${id}"

    input:
      tuple val(id), val(sex), val(family), val(trio), val(laneCount), val(famSampleCount), file(bam)

    output:
      tuple val(id), val(sex), val(family), val(trio),
            val(famSampleCount), file("${id}_fx.bam")

    script:
      """
        echo "[${id}] samtools fixmate"
        
        samtools fixmate -u -@ ${task.cpus} ${bam} - |
        samtools sort -@ ${task.cpus} -l 1 -O BAM -o ${id}_fx.bam -
      """
}
