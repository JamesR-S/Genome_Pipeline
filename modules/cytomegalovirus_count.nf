#!/usr/bin/env nextflow
process CYTOMEGALOVIRUS_COUNT {
    cpus 4
    tag { id.join('-') }
    publishDir "${params.batchDir}/r04_cytomegalovirus", mode: 'copy'
    input:
      tuple val(id), file(sam), file(cfq)
    output:
      file("stats")
    script:
      """
      java -Xmx1g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -cp ${params.javaDir}:${params.gatkJar} CytomegalovirusCountNF \\
        ${id.join(' ')} \\
        > stats
      """
}