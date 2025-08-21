process MARKDUP {
    cpus 16
    publishDir "${params.batchDir}/r04_assembly", mode: 'copy'
    container 'mgibio/samtools:v1.21-noble'
    containerOptions "-B ${params.resourcesDir} -B ${params.sambamba} -B ${params.picardJar}" 
    tag "${id}"

    input:
      tuple val(id), val(sex), val(family), val(trio),
            val(famSampleCount), file(fxbam)

    output:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file("${id}.cram"), file("${id}.cram.crai"), emit: cram

    script:
      """
      set -euo pipefail
      mkdir tmp
      fifo="${id}.dedup.fifo.bam"
      mkfifo "\$fifo"
      trap 'rm -f "\$fifo"' EXIT
      ${params.sambamba} markdup -t "${task.cpus}" --tmpdir=tmp ${fxbam} "\$fifo" &
      samtools view -@ "${task.cpus}" -T "${params.referenceFasta}" -O cram -o "${id}.cram" "\$fifo"
      wait
      
      samtools index -@ ${task.cpus} ${id}.cram

      """
}
