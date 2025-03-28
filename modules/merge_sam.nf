#!/usr/bin/env nextflow
process mergeSamFiles {
    tag "${sampleName}"
    publishDir "r03_assembly", mode: 'copy'
    input:
      tuple val(sampleName), file(sams)
    output:
      tuple val(sampleName), file("${sampleName}_merged.sam")
    script:
      """
      echo "Merging SAM files for sample ${sampleName}"
      inputs=""
      for f in ${sams.join(' ')}; do
         inputs="\${inputs} I=\$f"
      done
      java -jar ${params.picardJar} MergeSamFiles \${inputs} \
         O=${sampleName}_merged.sam SO=coordinate CREATE_INDEX=true TMP_DIR=${params.tmpDir}
      """
}
