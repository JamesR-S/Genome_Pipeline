#!/usr/bin/env nextflow
process EXTRACT_HLA {
    tag "${id}"
    module 'SAMtools/1.17-GCC-12.2.0'
    module 'BCFtools/1.17-GCC-12.2.0'
    publishDir "${params.batchDir}/r04_metrics", mode: 'copy', overwrite: true, failOnError: true
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(bam), file(bai)
    output:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file("${id}_hla_realigned.bam"), file("${id}_hla_realigned.bam.bai")
    script:
      """
        set -euo pipefail
        TMPDIR="\$PWD/temp"
        mkdir -p "\$TMPDIR"
        export TMPDIR
        export TEMP="\$TMPDIR"
        export TMP="\$TMPDIR"
        
        ${params.sambamba} markdup \
                -t ${task.cpus} \
                -f bam \
                -L ${params.hla_regions} \
                --show-progress \
                --tmpdir="\$TMPDIR" \
                ${bam} \
                -o ${id}_hla_contigs.bam

        samtools index -@ 16 ${id}_hla_contigs.bam
        
        samtools collate -u -O ${id}_hla_contigs.bam \
        | samtools fastq \
            -1 ${id}_hla_1.fq \
            -2 ${id}_hla_2.fq \
            -0 /dev/null -s /dev/null -n

        ${params.bwaMem2} mem -t 16 -M "${params.chr6_fasta}" \
            ${id}_hla_1.fq \
            ${id}_hla_2.fq \
        | samtools sort -@ 8 -O BAM -o "${id}_hla_realigned.bam" -

        samtools index -@ 8 "${id}_hla_realigned.bam"
      """
}