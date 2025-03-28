#!/usr/bin/env nextflow
process realignIndels {
    tag "${sampleName}"
    publishDir "r03_assembly", mode: 'copy'
    input:
      tuple val(sampleName), file(dedupBam) from dedupBams
    output:
      tuple val(sampleName), file("${sampleName}_realigned.bam") into realignedBams
    script:
    """
    echo "Running GATK indel realignment for sample ${sampleName}"
    # Create realignment intervals
    java -Djava.io.tmpdir=${params.tmpDir} -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -jar ${params.gatkJar} \
      -T RealignerTargetCreator \
      -R ${params.referenceFasta} \
      -I ${dedupBam} \
      -o ${sampleName}.intervals \
      -known ${params.goldStandardIndels}
    # Realign indels
    java -Djava.io.tmpdir=${params.tmpDir} -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -jar ${params.gatkJar} \
      -T IndelRealigner \
      -R ${params.referenceFasta} \
      -I ${dedupBam} \
      -targetIntervals ${sampleName}.intervals \
      -o ${sampleName}_realigned.bam \
      -known ${params.goldStandardIndels} \
      --maxReadsInMemory 100000000 --maxReadsForRealignment 600000
    """
}