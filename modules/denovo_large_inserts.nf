process DENOVO_LARGE_INSERTS {
    tag { trio_ids.join('-') }
    cpus 4
    publishDir "r04_denovolargeinserts", mode: 'copy'
    
    input:
      tuple val(id), val(sex), val(trio_ids), file(bam), file(bai)
    output:
      tuple val(id), val(sex), val(trio_ids), file("*.csv")
    script:
      """
      java -Xmx9g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -cp ${params.javaDir}:${params.gatkJar} FindLargeInsertSizes \\
        ${bam[0]} \\
        ${bam[0]} \\
        ${bam[1]} \\
        ${bam[2]} \\
        > ${trio_ids.join("-")}.csv
      """
}