process COVERAGE_REPORT {
    tag { id.join('-') }
    cpus 1
    publishDir("r04_metrics", mode: 'copy')
    
    input:
      tuple val(id), val(sex), file(coverage)
    output:
      tuple val(id), val(sex), file("coverage_report")
    script:
      """
      java -Xmx1g -XX:ParallelGCThreads=1 -XX:ConcGCThreads=1 -cp ${params.javaDir} CoverageReport \\
        ${coverage} \\
        ${params.base}/resources/grch38-v2-pipeline/variantcall.bed \\
        > coverage_report
      """
}