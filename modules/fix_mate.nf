#!/usr/bin/env nextflow
process FIXMATE {
    tag "${id}"
    publishDir "r03_assembly", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(sam), file(sai)
    output:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file("${id}_fixmate.bam"), file("${id}_fixmate.bai")
    script:
      """
      echo "Running Picard FixMateInformation for sample ${id}"
      java -Xmx4g -jar ${params.picardJar} FixMateInformation \
      I=${sam} \
      O=${id}_fixmate.bam \
      VALIDATION_STRINGENCY=SILENT \
      CREATE_INDEX=true \
      TMP_DIR=${params.tmpDir}
      """
}
