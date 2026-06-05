process DEPTH_OF_COVERAGE {
    tag "batch_${id[0]}"
    cpus 16
    
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(bam), file(bai)
    output:
      tuple val(id), val(sex), file("Coverage")
    script:
      """
      java -Xmx8g -XX:ParallelGCThreads=8 -XX:ConcGCThreads=8 -cp ${params.javaDir}:${params.gatkJar} DepthOfCoverage \\
        -nt 16 \\
        ${bam.collect{ "-I ${it}" }.join(' ')} \\
        -L ${params.base}/resources/grch38-v2-pipeline/variantcall.bed \\
        -mmq 30 \\
        > Coverage
      """
}
