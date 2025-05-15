#!/usr/bin/env nextflow
process PARABRICKS_FQ2BAM {
    cpus 8
    clusterOptions '--gres=gpu:1'
    queue 'gpu'
    tag "${meta.id}"
    // stageInMode 'copy'
    container 'nvcr.io/nvidia/clara/clara-parabricks:4.5.0-1'
    containerOptions "--nv -B ${params.bwaMem1RefDir}"

    input:
      tuple val(meta), val(flowcell), file(fastq1), file(fastq2)

    output:
      tuple val(meta.id), val(meta.sex), val(meta.family), val(meta.trio), val(meta.famSampleCount),
            file("${meta.id}_markdup.bam"),file("${meta.id}_markdup.bam.bai")

    script:

      def inFqStr = fastq1
          .withIndex()
          .collect { r1, idx ->
              "--in-fq ${r1} ${fastq2[idx]} \"@RG\\tID:${flowcell[idx]}\\tPL:${meta.platform}\\tPU:${flowcell[idx]}.${meta.id}\\tSM:${meta.id}\\tLB:${meta.id}_${flowcell[idx]}\""
          }
          .join(' ')

      """
      pbrun fq2bam \
        --ref ${params.bwaMem1RefDir}/Homo_sapiens_assembly38.fasta \
        ${inFqStr} \
        --out-bam ${meta.id}_markdup.bam
      """

}
