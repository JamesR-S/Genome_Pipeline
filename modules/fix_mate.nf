#!/usr/bin/env nextflow
process FIXMATE {
    cpus 8
    module 'SAMtools/1.22.1-GCC-14.2.0'
    tag "${id}"

    input:
      tuple val(id), val(sex), val(family), val(trio), val(laneCount), val(famSampleCount), file(bam)

    output:
      tuple val(id), val(sex), val(family), val(trio),
            val(famSampleCount), file("${id}_fx.bam")

    script:
      """
        echo "[${id}] samtools fixmate"
        
        samtools fixmate -u -@ 2 ${bam} - |
        ${params.mako} \
            --order coordinate \
            --threads 6 \
            --compression-level 1 \
            -i /dev/stdin \
            -o "${id}_fx.bam"
      """
}
