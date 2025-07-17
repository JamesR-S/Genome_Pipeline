process CRAM2BAM {
    tag "${id}"
    cpus 4
    container 'mgibio/samtools:v1.21-noble'
    containerOptions "-B ${params.resourcesDir}"

    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(cram), file(crai)

    output:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file("${id}.bam"), file("${id}.bam.bai")

    script:
      """
      set -euo pipefail

      samtools view  -@ ${task.cpus} -T ${params.referenceFasta} -O bam ${cram} |
      samtools sort  -@ ${task.cpus} -l 1 -o ${id}.bam -

      samtools index -@ ${task.cpus} ${id}.bam
      """
}