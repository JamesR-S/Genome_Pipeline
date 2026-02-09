process MARKDUP {
  cpus 16
  publishDir "${params.batchDir}/r04_assembly", mode: 'copy', overwrite: true, failOnError: true
  container 'mgibio/samtools:v1.21-noble'
  containerOptions "-B ${params.resourcesDir} -B ${params.sambamba} -B ${params.picardJar}"
  tag "${id}"

  input:
    tuple val(id), val(sex), val(family), val(trio),
          val(famSampleCount), file(fxbam)

  output:
    tuple val(id), val(sex), val(family), val(trio), val(famSampleCount),
          file("${id}.cram"), file("${id}.cram.crai"), emit: cram

  script:
  """
  set -euo pipefail
  mkdir -p tmp
  tmp="${id}.tmp.bam"
  trap 'rm -f \$tmp' EXIT
  
  ${params.sambamba} markdup -t ${task.cpus} -l 3 --show-progress --tmpdir=tmp ${fxbam} \$tmp
  
  samtools view \
        -@ ${task.cpus} \
        -T "${params.referenceFasta}" \
        -O cram \
        -o ${id}.cram \
        \$tmp

  samtools index -@ ${task.cpus} "${id}.cram"
  """
}
