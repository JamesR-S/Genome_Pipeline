process RMDUP {
    cpus 8
    publishDir "${params.batchDir}/r04_assembly", mode: 'copy'
    container 'mgibio/samtools:v1.21-noble'
    tag "${id}"

    input:
      tuple val(id), val(sex), val(family), val(trio),
            val(famSampleCount), file(mdbam), file(mdbai)

    output:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file("${id}.bam"), file("${id}.bam.bai")

    script:
      """
        samtools view -@ 8 -h -b -F 0x400 ${mdbam} -o ${id}.bam
        samtools index ${id}.bam
      """
}
