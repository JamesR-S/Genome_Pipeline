#!/usr/bin/env nextflow
process sumReadCounts {
    tag "${sample.name}"
    publishDir "r04_metrics", mode: 'copy'
    input:
      tuple val(sample), file(countFiles)
    output:
      tuple val(sample), file("${sample.name}_checkFastq.txt")
    script:
    """
    echo "Summing read counts for sample ${sampleName}"
    total=0
    # Convert countFiles into a bash array
    files=( ${countFiles} )
    for f in "\${files[@]}"; do
       count=\$(cat "\$f")
       total=\$(expr \$total + \$count)
    done
    echo \$total > ${sampleName}_checkFastq.txt
    """
}