#!/usr/bin/env nextflow
process fixMate {
    tag "${sampleName}"
    publishDir "r03_assembly", mode: 'copy'
    input:
      tuple val(sampleName), file(sam), file(sai)
    output:
      tuple val(sampleName), file("${sampleName}_fixmate.bam"), file("${sampleName}_fixmate.bai")
    script:
      """
      echo "Running Picard FixMateInformation for sample ${sampleName}"
      java -Xmx4g -jar ${params.picardJar} FixMateInformation \
      I=${sam} \
      O=${sampleName}_fixmate.bam \
      VALIDATION_STRINGENCY=SILENT \
      CREATE_INDEX=true \
      TMP_DIR=${params.tmpDir}
      """
}
