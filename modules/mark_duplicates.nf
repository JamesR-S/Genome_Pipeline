process MARKDUP {
    cpus 16
    publishDir "${params.batchDir}/r04_assembly", mode: 'copy'
    container 'mgibio/samtools:v1.21-noble'
    containerOptions "-B ${params.resourcesDir}"
    tag "${id}"

    input:
      tuple val(id), val(sex), val(family), val(trio),
            val(famSampleCount), file(fxbam)

    output:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file("${id}.cram"), file("${id}.cram.crai"), emit: cram
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file("${id}.markdup_metrics"), emit: metrics

    script:
      """
      set -euo pipefail
      echo "[${id}] coordinate-sort"
      samtools sort -@ ${task.cpus} -l 1 -o ${id}_pos.bam ${fxbam}

      echo "[${id}] samtools markdup (remove dups, stats)"
      samtools sort -@ ${task.cpus} -l 1 -o - ${fxbam} |
      samtools markdup -@ ${task.cpus} -s -d 100 -f ${id}.markdup_metrics - -  |
      samtools view -@ ${task.cpus} -T ${params.referenceFasta} -O cram -o ${id}.cram -
      
      samtools index -@ ${task.cpus} ${id}.cram
      """
}
