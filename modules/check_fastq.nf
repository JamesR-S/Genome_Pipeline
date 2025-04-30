#!/usr/bin/env nextflow
process CHECK_FASTQ {
    tag "${meta.id}"
    input:
      // Accept a sample map
       tuple val(meta), val(fastqFiles)
    output:
      // Output a tuple: the sample map and the QC file.
      tuple val(meta.id), val(meta.sex), val(meta.family), val(meta.famSampleCount), file("${meta.id}_checkFastq.txt")
    script:
    """
    java -Xmx4g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -cp ${params.javaDir} CheckFastq ${fastqFiles.collect{ fq -> "${fq.R1} ${fq.R2}"}.join(" ")} \\
    > ${meta.id}_checkFastq.txt
    """
}
