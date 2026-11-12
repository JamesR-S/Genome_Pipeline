#!/usr/bin/env nextflow
process FIXMATE {
    cpus 12
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
        
        samtools fixmate -u -@ 4 ${bam} - |
        samtools sort -@ 8 -l 1 -O BAM -o ${id}_fx.bam -
      """
}
