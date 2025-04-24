#!/usr/bin/env nextflow
process CHECK_FASTQ {
    tag "${id}"
    input:
      // Accept a sample map
       tuple val(id), val(platform), val(sex), val(family), val(trio), val(flowcell), val(laneCount), val(famSampleCount), val(fastqFiles)
    output:
      // Output a tuple: the sample map and the QC file.
      tuple val(id), val(sex), val(family), val(trio), val(laneCount), val(famSampleCount), file("${id}_${flowcell}.ct")
    script:
    """
    echo "Running CheckFastq for sample ${id} ${flowcell} ? "(${flowcell})" : ""}"
    java -Xmx4g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -cp ${params.javaDir} CheckFastq fastq/\${sample.fastq1} fastq/\${sample.fastq2} > ${id}_${flowcell}.ct
    """
}
