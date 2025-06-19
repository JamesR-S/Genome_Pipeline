process XY_COVERAGE {
    tag "batch_${ids[0]}-${ids[-1]}"
    cpus 1
    publishDir("${params.batchDir}/r04_metrics", mode: 'copy')
    container 'docker://amazoncorretto:21.0.7'
    containerOptions "-B ${params.javaDir} -B ${params.gatkJar}"    
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

      java -Xmx1g -XX:ParallelGCThreads=1 -XX:ConcGCThreads=1 -cp ${params.javaDir}:${params.javaDir}/jars/htsjdk-4.2.0.jar XYCoverageCHRPrefix \\
        ${coverage} \\
        -v genome \\
        \$id_flags \\
        > XY_coverage
      """
}