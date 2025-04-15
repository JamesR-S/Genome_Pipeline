#!/usr/bin/env nextflow
process MARKDUP {
    tag "${id}"
    publishDir "r03_assembly", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(fixmateBam), file(fixmateBai)
    output:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file("${id}_dedup.bam"), file("${id}_dedup.bai")
    script:
      """
      echo "Running Picard MarkDuplicates for sample ${id}"
      java -jar ${params.picardJar} MarkDuplicates \
      I=${fixmateBam} \
      O=${id}_dedup.bam \
      METRICS_FILE=${id}.metrics \
      REMOVE_DUPLICATES=true \
      CREATE_INDEX=true \
      VALIDATION_STRINGENCY=SILENT \
      TMP_DIR=${params.tmpDir}
      """
}
