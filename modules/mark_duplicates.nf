#!/usr/bin/env nextflow
process MARKDUP {
    tag "${id}"
    publishDir "${params.batchDir}/r04_assembly", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(fixmateBam), file(fixmateBai)
    output:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file("${id}.bam"), file("${id}.bai")
    script:
      """
      mkdir temp_files
      tmp_dir="\$PWD/temp_files"
      echo "Running Picard MarkDuplicates for sample ${id}"
      java \
      -Djava.io.tmpdir="\$tmp_dir" \
      -jar ${params.picardJar} MarkDuplicates \
      I=${fixmateBam} \
      O=${id}.bam \
      METRICS_FILE=${id}.metrics \
      REMOVE_DUPLICATES=true \
      CREATE_INDEX=true \
      VALIDATION_STRINGENCY=SILENT \
      TMP_DIR=\${tmp_dir}
      """
}
