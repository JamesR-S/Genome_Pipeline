#!/usr/bin/env nextflow
process CHECK_FASTQ {
    tag "${meta.id}"
    publishDir "${params.batchDir}/r04_metrics", mode: 'copy' 
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
