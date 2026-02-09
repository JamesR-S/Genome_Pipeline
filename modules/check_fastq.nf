#!/usr/bin/env nextflow
process CHECK_FASTQ {
    tag "${meta.id}"
    publishDir "${params.batchDir}/r04_metrics", mode: 'copy', overwrite: true, failOnError: true
    container 'docker://amazoncorretto:21.0.7'
    containerOptions "-B ${params.javaDir} -B ${params.base}"
    input:
      // Accept a sample map
       tuple val(meta), file(fastq1), file(fastq2)
    output:
      // Output a tuple: the sample map and the QC file.
      tuple val(meta.id), val(meta.sex), val(meta.family), val(meta.famSampleCount), file("${meta.id}_checkFastq.txt")
    script:
    """

    java -Xmx4g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -cp ${params.javaDir} CheckFastq2 ${ fastq1.withIndex().collect { f1, idx -> "${f1} ${fastq2[idx]}" }.join(' ') } \\
    > ${meta.id}_checkFastq.txt
    
    """
}
