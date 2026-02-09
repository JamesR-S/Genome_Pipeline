process COVERAGE_REPORT {
    tag "batch ${id[0]}"
    cpus 1
    publishDir "${params.batchDir}/r04_metrics", mode: 'copy', overwrite: true, failOnError: true
    container 'docker://amazoncorretto:21.0.7'
    containerOptions "-B ${params.javaDir} -B ${params.base}"
    
    input:
      tuple val(id), val(sex), file(coverage)
    output:
      tuple val(id), val(sex), file("coverage_report")
    script:
      """
      java -Xmx1g -XX:ParallelGCThreads=1 -XX:ConcGCThreads=1 -cp ${params.javaDir} CoverageReport \\
        ${coverage} \\
        ${params.easyRegions} \\
        > coverage_report
      """
}
