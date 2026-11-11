#!/usr/bin/env nextflow
process BWA_MEM {
    cpus 16
    tag "${id}"
    stageInMode 'copy'
    // built from containers/bwa_mem_alt_aware
    container "${params.bwaAltAwareContainer}"
    containerOptions "-B ${params.resourcesDir}"

    input:
      tuple val(id), val(platform), val(sex), val(family), val(trio),
            val(flowcell), val(laneCount), val(famSampleCount),
            file(fastq1), file(fastq2)

    output:
      tuple val(id), val(sex), val(family), val(trio),
            val(laneCount), val(famSampleCount),
            file("${id}_${flowcell}_ns.bam"), emit: bam

    script:
    def mode = task.attempt
      """
      set -o pipefail
      mkdir -p \$PWD/temp
      export TMPDIR=\$PWD/temp

      if [[ ${mode} -eq 1 ]]; then
      echo "[${id}|${flowcell}] bwa-mem2 → name-sorted BAM"
      BWA=bwa-mem2
      INDEX=${params.referenceFasta}
      else
      echo "Fallback to bwa → name-sorted BAM"
      BWA=bwa
      INDEX=${params.resourcesDir}/bwa-mem1/\$(basename ${params.referenceFasta})
      fi

      # all lanes have to be aligned the same way, so the fallback index needs a .alt file too
      if [[ -s "${params.referenceFasta}.alt" && ! -s "\$INDEX.alt" ]]; then
        echo "ERROR: ${params.referenceFasta}.alt exists but \$INDEX.alt does not" >&2
        exit 1
      fi

      # bwa-postalt.js fixes the mapping quality of reads that also hit ALT contigs. It has to run on
      # bwa's output before sorting. No -p, we don't need its HLA read files.
      if [[ -s "\$INDEX.alt" ]]; then
        POSTALT=( k8 /opt/bwakit/bwa-postalt.js "\$INDEX.alt" )
      else
        POSTALT=( cat )
      fi

      \$BWA mem -t 12 -M \
        -R "@RG\\tID:${flowcell}\\tPL:${platform}\\tSM:${id}\\tLB:${id}_${flowcell}" \
        \$INDEX ${fastq1} ${fastq2} 2> bwa.log \
      | "\${POSTALT[@]}" 2> postalt.log \
      | samtools sort -n -@ 4 -l 1 -O BAM -o ${id}_${flowcell}_ns.bam -
      cat bwa.log >&2
      cat postalt.log >&2

      if [[ -s "\$INDEX.alt" ]] && ! grep -qiE "read [1-9][0-9]* ALT contigs" bwa.log; then
        echo "ERROR: \$INDEX.alt exists but \$BWA did not load it" >&2
        exit 1
      fi
      """
      
}
