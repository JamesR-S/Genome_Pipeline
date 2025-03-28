#!/usr/bin/env nextflow
process mergeSamFiles {
    tag "${sampleName}"
    publishDir "r03_assembly", mode: 'copy'
    input:
      // Group all SAM files by sample name
      tuple val(sampleName), file(sams) from samFiles.groupTuple().collect { k,v -> [k, v] }
    output:
      tuple val(sampleName), file("${sampleName}_merged.sam") into mergedSamFiles
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
