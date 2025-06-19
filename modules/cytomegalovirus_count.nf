#!/usr/bin/env nextflow
process CYTOMEGALOVIRUS_COUNT {
    cpus 4
    tag "batch_${id[0]}"
    publishDir "${params.batchDir}/r04_cytomegalovirus", mode: 'copy'
    container 'docker://amazoncorretto:21.0.7'
    containerOptions "-B ${params.javaDir} -B ${params.gatkJar}"
    input:
      tuple val(id), file(sam), file(cfq)
    output:
      file("stats")
    script:
      """
      java -Xmx1g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -cp ${params.javaDir}:${params.gatkJar}:${params.javaDir}/jars/htsjdk-4.2.0.jar CytomegalovirusCountNF \\
        ${id.join(' ')} \\
        > stats
      """
}