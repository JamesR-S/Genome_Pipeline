#!/usr/bin/env nextflow
process MANTA {
    cpus 16
    tag { id.join('-') }
    container 'informationsea/manta:1.6.0'
    containerOptions('-B /usr/lib/locale/:/usr/lib/locale/')
    publishDir(path: { "${params.batchDir}/r04_manta" },
        mode: 'copy')

    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(bam), file(bai)
      file(fasta)
      file(fai)
      file(mantaBed)
      file(mantaBedIDX)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("*.SV.vcf.gz"), file("*.SV.vcf.gz.csi")

    script:

      def inBamStr = bam
          .withIndex()
          .collect { bam, idx ->
              "--bam ${bam}"
          }
          .join(' ')

      """
      mkdir manta_rundir

      /manta-1.6.0.centos6_x86_64/bin/configManta.py \
        --referenceFasta ${fasta} \
        --runDir manta_rundir \
        --callRegions ${mantaBed} \
        ${inBamStr}

      manta_rundir/runWorkflow.py
      mv manta_rundir/results/variants/diploidSV.vcf.gz ${id.join("-")}.SV.vcf.gz
      """

}
