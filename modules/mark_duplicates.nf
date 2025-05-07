process MARKDUP {
    cpus 16
    publishDir "${params.batchDir}/r04_assembly", mode: 'copy'
    container 'mgibio/samtools:v1.21-noble'
    tag "${id}"

    input:
      tuple val(id), val(sex), val(family), val(trio),
            val(famSampleCount), file(fxbam)

    output:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file("${id}.bam"), file("${id}.bam.bai"), emit: bam
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file("${id}.markdup_metrics"), emit: metrics

    script:
      """
      set -euo pipefail
      echo "[${id}] coordinate-sort"
      samtools sort -@ ${task.cpus} -l 1 -o ${id}_pos.bam ${fxbam}

      echo "[${id}] samtools markdup (remove dups, stats)"
      samtools markdup -@ ${task.cpus} -r -s -d 100 \
          -f ${id}.markdup_metrics ${id}_pos.bam ${id}.bam

      samtools index -@ ${task.cpus} ${id}.bam
      """
}
