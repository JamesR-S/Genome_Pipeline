#!/usr/bin/env nextflow
process BWA_MEM {
    cpus 16
    tag "${id}"
    stageInMode 'copy'
    module 'SAMtools/1.17-GCC-12.2.0'

    input:
      tuple val(id), val(platform), val(sex), val(family), val(trio),
            val(flowcell), val(laneCount), val(famSampleCount),
            file(fastq1), file(fastq2)

    output:
      tuple val(id), val(sex), val(family), val(trio),
            val(laneCount), val(famSampleCount),
            file("${id}_${flowcell}_ns.bam")

    script:
        
        def mode = task.attempt
        """
        mkdir -p \$PWD/temp
        export TMPDIR=\$PWD/temp
        set -o pipefail
        
        postalt() {
            if [[ -f "${params.referenceFasta}.alt" ]]; then
                echo "ALT file detected: running bwa-postalt.js" >&2
                ${params.software}/bwa-mem/bwa-0.7.19/bwakit/k8-1.2/k8-x86_64-Linux \
                  ${params.software}/bwa-mem/bwa-0.7.19/bwakit/bwa-postalt.js \
                  ${params.referenceFasta}.alt
            else
                cat
            fi
        }
        
        if [[ ${mode} -eq 1 ]]; then
            echo "[${id}|${flowcell}] bwa-mem2 → name-sorted BAM"
            ${params.bwaMem2} mem -t 12 -M \
              -R "@RG\\tID:${flowcell}\\tPL:${platform}\\tSM:${id}\\tLB:${id}_${flowcell}" \
              ${params.referenceFasta} ${fastq1} ${fastq2} \
            | postalt \
            | samtools sort -n -@ 4 -l 1 -O BAM -o ${id}_${flowcell}_ns.bam -
        else
            echo "Fallback to bwa → name-sorted BAM"
            ${params.bwaMem1} mem -t 12 -M \
              -R "@RG\\tID:${flowcell}\\tPL:${platform}\\tSM:${id}\\tLB:${id}_${flowcell}" \
              ${params.resourcesDir}/bwa-mem1/\$(basename ${params.referenceFasta}) ${fastq1} ${fastq2} \
            | postalt \
            | samtools sort -n -@ 4 -l 1 -O BAM -o ${id}_${flowcell}_ns.bam -
        fi
        """
