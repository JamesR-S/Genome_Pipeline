process INSERT_SIZES {
    tag "${id}"
    cpus 2
    publishDir("${params.batchDir}/r04_metrics", mode: 'copy', overwrite: true, failOnError: true)
    
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(bam), file(bai)
    output:
      tuple val(id), val(sex), file("${id}.insertSize.histogram"), file("${id}.insertSize.stats")
    script:
      """
      java -Xmx5g -XX:ParallelGCThreads=2 -XX:ConcGCThreads=2 -cp ${params.javaDir}:${params.gatkJar} InsertSizeHistogram \\
        ${bam} \\
        chr1 \\
        80000000 \\
        100000000 \\
        > ${id}.insertSize.histogram 2> ${id}.insertSize.stats
      """
}