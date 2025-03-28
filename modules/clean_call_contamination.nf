#!/usr/bin/env nextflow
process cleanCallContamination {
    tag "${sample.name}"
    publishDir "r03_metrics", mode: 'copy'
    input:
      tuple val(sample.name), file(bam)
    output:
      tuple val(sample.name), file("${sample.name}_cleanCall.csv")
    script:
      """
      echo "Running cleanCall-contamination3.sh for sample ${sample.name}"
      ${params.auxSoftware}/cleanCall-contamination3.sh ${sample.name}
      """
}

process cleanCallContaminationSmall {
    tag "${sample.name}"
    publishDir "r03_metrics", mode: 'copy'
    input:
      tuple val(sample.name), file(bam)
    output:
      tuple val(sample.name), file("${sample.name}_cleanCall_small.csv")
    script:
      """
      echo "Running cleanCall-contamination3_small.sh for sample ${sample.name}"
      ${params.auxSoftware}/cleanCall-contamination3_small.sh ${sample.name}
      """
}
