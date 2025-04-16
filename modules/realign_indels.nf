#!/usr/bin/env nextflow
process INDEL_REALIGN {
    tag "${id}"
    publishDir "r03_assembly", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(dedupBam), file(dedupBai)
    output:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file("${id}.bam"), file("${id}.bai")
    script:
      """
      echo "Running GATK indel realignment for sample ${id}"
      # Create realignment intervals
      java -Djava.io.tmpdir=${params.tmpDir} -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -jar ${params.gatkJar} \
      RealignerTargetCreator \
      -R ${params.referenceFasta} \
      -I ${dedupBam} \
      -o ${id}.intervals \
      -known ${params.goldStandardIndels}
      # Realign indels
      java -Djava.io.tmpdir=${params.tmpDir} -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -jar ${params.gatkJar} \
      IndelRealigner \
      -R ${params.referenceFasta} \
      -I ${dedupBam} \
      -targetIntervals ${id}.intervals \
      -o ${id}_realigned.bam \
      -known ${params.goldStandardIndels} \
      --maxReadsInMemory 100000000 --maxReadsForRealignment 600000
      """
}
