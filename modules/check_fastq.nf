#!/usr/bin/env nextflow
process CHECK_FASTQ {
    tag "${id}"
    input:
      // Accept a sample map
       tuple val(id), val(platform), val(sex), val(family), val(trio), val(flowcell), val(laneCount), val(famSampleCount), val(fastqFiles)
    output:
      // Output a tuple: the sample map and the QC file.
      tuple val(id), val(sex), val(family), val(trio), val(laneCount), val(famSampleCount), file("${id}_checkFastq.txt")
    script:
    """
    java -Xmx4g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -cp ${params.javaDir} CheckFastq ${fastqFiles.collect{ fq -> "${fq.R1} ${fq.R2}"}.join(" ")} \\
    > ${id}_checkFastq.txt
    """
}
