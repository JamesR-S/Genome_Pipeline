process CLIP_RATE {
    tag "${id}"
    cpus 2
    publishDir("r04_metrics", mode: 'copy')
    
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(bam), file(bai)
    output:
      tuple val(id), val(sex), file("${id}.clipRate")
    script:
      """
      java -Xmx5g -XX:ParallelGCThreads=2 -XX:ConcGCThreads=2 -cp ${params.javaDir}:${params.gatkJar} BamDoubleClipRate \\
        ${bam} \\
        > ${id}.clipRate
      """
}