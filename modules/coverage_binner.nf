process COVERAGE_BINNER {
    tag "${id}"
    cpus 2
    publishDir("r04_metrics", mode: 'copy')
    
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(bam), file(bai)
    output:
      tuple val(id), val(sex), file("${id}.coverageBinner")
    script:
      """
      java -Xmx5g -XX:ParallelGCThreads=2 -XX:ConcGCThreads=2 -cp ${params.javaDir}:${params.gatkJar} CoverageBinner \\
        ${bam} \\
        > ${id}.coverageBinner
      """
}