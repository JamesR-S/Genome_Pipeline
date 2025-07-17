process BAM2CRAM {
    cpus 8
    publishDir "${params.batchDir}/r04_assembly", mode: 'copy'
    container 'mgibio/samtools:v1.21-noble'
    containerOptions "-B ${params.resourcesDir}"
    tag "${id}"

    input:
      tuple val(id), val(sex), val(family), val(trio),
            val(famSampleCount), file(mdbam), file(mdbai)

    output:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file("${id}.cram"), file("${id}.cram.crai")

    script:
      """
        samtools view -@ 8 -T ${params.referenceFasta} -O cram -o ${id}.cram ${mdbam}
        samtools index ${id}.cram
      """
}
