#!/usr/bin/env nextflow
process markDuplicates {
    tag "${sampleName}"
    publishDir "r03_assembly", mode: 'copy'
    input:
      tuple val(sampleName), file(fixmateBam)
    output:
      tuple val(sampleName), file("${sampleName}_dedup.bam")
    script:
      """
      echo "Running Picard MarkDuplicates for sample ${sampleName}"
      java -jar ${params.picardJar} MarkDuplicates \
      I=${fixmateBam} \
      O=${sampleName}_dedup.bam \
      METRICS_FILE=${sampleName}.metrics \
      REMOVE_DUPLICATES=true \
      CREATE_INDEX=true \
      VALIDATION_STRINGENCY=SILENT \
      TMP_DIR=${params.tmpDir}
      """
}
