#!/usr/bin/env nextflow
process checkFastq {
    tag "${sample.name}"
    publishDir "r04_metrics", mode: 'copy'
    input:
      // Accept a sample map
      val sample
    output:
      // Output a tuple: the sample map and the QC file.
      tuple val(sample), file("${sample.name}${sample.lane ?: ''}_checkFastq.txt")
    script:
    """
    echo "Running CheckFastq for sample ${sample.name} ${sample.lane ? "(${sample.lane})" : ""}"
    # Suppose the CheckFastq tool prints the total number of reads into the QC file.
    java -Xmx4g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -cp ${params.javaDir} CheckFastq fastq/\${sample.fastq1} fastq/\${sample.fastq2} > ${sample.name}${sample.lane ?: ''}_checkFastq.txt
    """
}
