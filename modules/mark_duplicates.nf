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
      ${params.sambamba} markdup -t "${task.cpus}" --tmpdir=tmp ${fxbam} ${id}.dedup.bam
      samtools view -@ ${task.cpus} -T "${params.referenceFasta}" -O cram -o "${id}.cram" ${id}.dedup.bam
      rm -f ${id}.dedup.bam
      
      samtools index -@ ${task.cpus} ${id}.cram

      """
}
