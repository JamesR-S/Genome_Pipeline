process DUPMETRICS {
    cpus 2
    memory '24 GB'
    publishDir "${params.batchDir}/r04_assembly", mode: 'copy'
    container 'docker://amazoncorretto:21.0.7'
    containerOptions "-B ${params.resourcesDir} -B ${params.picardJar}" 
    tag "${id}"

    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(bam), file(bai)

    output:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file("${id}.markdup_metrics"), emit: metrics

    script:
      """
      java -Xmx24g -jar ${params.picardJar} CollectDuplicateMetrics \
      INPUT=${bam} \
      METRICS_FILE=${id}.markdup_metrics
      VALIDATION_STRINGENCY=SILENT \
      REFERENCE_SEQUENCE=${params.referenceFasta}
      """
}
