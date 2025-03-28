#!/usr/bin/env nextflow
process fixMate {
    tag "${sampleName}"
    publishDir "r03_assembly", mode: 'copy'
    input:
      tuple val(sampleName), file(sam)
    output:
      tuple val(sampleName), file("${sampleName}_fixmate.bam")
    script:
      """
      echo "Running Picard FixMateInformation for sample ${sampleName}"
      java -Xmx4g -cp ${params.picardJar} FixMateInformation \
      I=${sam} \
      O=${sampleName}_fixmate.bam \
      VALIDATION_STRINGENCY=SILENT \
      CREATE_INDEX=true \
      TMP_DIR=${params.tmpDir}
      """
}
