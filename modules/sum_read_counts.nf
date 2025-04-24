#!/usr/bin/env nextflow
process SUM_READ_COUNTS {
    tag "${meta.id}"
    executor 'local'
    publishDir "r04_metrics", mode: 'copy'
    input:
      tuple val(meta), file(ct)
    output:
      tuple val(meta.id), file("${meta.id}_checkFastq.txt")
    script:
    """
    ct_files=( ${ct.join(" ")} )
    num_files=\$(echo \${ct_files[@]} | wc -w)
    if [ \$num_files -gt 1 ]; then
       awk '{s+=\$1} END {print s}' "\${ct_files[@]}" > ${meta.id}_checkFastq.txt
    else
        cp ${ct} ${meta.id}_checkFastq.txt
    fi
    """
}