#!/usr/bin/env nextflow
process checkFastq {
    tag "${sample.name}"
    publishDir "r03_metrics", mode: 'copy'
    input:
      val sample
    output:
      tuple val(sample.name), file("${sample.name}_checkFastq.txt") into checkedSamples
    script:
    """
    echo "Running CheckFastq for sample ${sample.name}"
    java -Xmx4g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -cp ${params.javaDir} CheckFastq fastq/${sample.fastq1} fastq/${sample.fastq2} > ${sample.name}_checkFastq.txt
    """
}