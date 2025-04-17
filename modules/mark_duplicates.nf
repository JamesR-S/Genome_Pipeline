#!/usr/bin/env nextflow
process MARKDUP {
    tag "${id}"
    publishDir "r04_assembly", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(fixmateBam), file(fixmateBai)
    output:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file("${id}.bam"), file("${id}.bai")
    script:
      """
      mkdir tmp

      echo "Running Picard MarkDuplicates for sample ${id}"
      java -jar ${params.picardJar} MarkDuplicates \
      I=${fixmateBam} \
      O=${id}.bam \
      METRICS_FILE=${id}.metrics \
      REMOVE_DUPLICATES=true \
      CREATE_INDEX=true \
      VALIDATION_STRINGENCY=SILENT \
      TMP_DIR=tmp
      """
}
