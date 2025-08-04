process INDEX_COVERAGE {
    tag "batch_${id[0]}"
    cpus 1
    publishDir("${params.batchDir}/r04_metrics", mode: 'copy')
    container 'docker://amazoncorretto:21.0.7'
    containerOptions "-B ${params.javaDir} -B ${params.base}"
    input:
      tuple val(id), val(sex), file(coverage)
      file(control)
    output:
      tuple val(id), val(sex), file("Coverage.indexed")
    script:
      """
      #!/usr/bin/env bash
      java \\
        -Xmx1g \\
        -XX:ParallelGCThreads=1 \\
        -XX:ConcGCThreads=1 \\
        -cp ${params.javaDir} \\
        IndexedCoverageFile2NF \\
        ${coverage} \\
        ${control} \\
        ${params.base}/resources/grch38-v2-pipeline/variantcall.bed \\
        > Coverage.indexed
      """
}