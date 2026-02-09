process DENOVO_LARGE_INSERTS {
    tag { trio_ids.join('-') }
    cpus 4
    publishDir "${params.batchDir}/r04_denovolargeinserts", mode: 'copy', overwrite: true, failOnError: true
    container 'docker://amazoncorretto:21.0.7'
    containerOptions "-B ${params.javaDir} -B ${params.gatkJar}"    
    input:
      tuple val(id), val(sex), val(trio_ids), file(bam), file(bai)
    output:
      tuple val(id), val(sex), val(trio_ids), file("*.csv")
    script:
      """
      java -Xmx9g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -cp ${params.javaDir}:${params.gatkJar}:${params.javaDir}/jars/htsjdk-4.2.0.jar FindLargeInsertSizesNF \\
        ${bam[0]} \\
        ${bam[0]} \\
        ${bam[1]} \\
        ${bam[2]} \\
        > ${trio_ids.join("-")}.csv
      """
}