process XY_COVERAGE {
    tag { ids.join('-') }
    cpus 1
    publishDir("r04_metrics", mode: 'copy')
    
    input:
      tuple val(ids), val(sex), file(coverage)
    output:
      tuple val(ids), val(sex), file("XY_coverage")
    script:
      """

      id_flags="${ ids.withIndex()
                     .findAll { id, idx ->
                         def s = sex[idx]?.toUpperCase()
                         s == 'MALE' || s == 'FEMALE'
                     }
                     .collect { id, idx ->
                         sex[idx].equalsIgnoreCase('MALE') ? "-m ${id}" : "-f ${id}"
                     }
                     .join(' ') }"

      java -Xmx1g -XX:ParallelGCThreads=1 -XX:ConcGCThreads=1 -cp ${params.javaDir} XYCoverageCHRPrefix \\
        ${coverage} \\
        -v genome \\
        \$id_flags \\
        > XY_coverage
      """
}