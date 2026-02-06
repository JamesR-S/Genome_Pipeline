#!/usr/bin/env nextflow
process MANTA {
    cpus 16
    memory '100G'
    tag { id.join('-') }
    container 'https://depot.galaxyproject.org/singularity/manta:1.6.0--h9ee0642_1'
    containerOptions('-B /usr/lib/locale/:/usr/lib/locale/')
    publishDir(path: { "${params.batchDir}/r04_manta" },
        mode: 'copy', overwrite: true, failOnError: true)

    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(bam), file(bai)
      file(fasta)
      file(fai)
      file(mantaBed)
      file(mantaBedIDX)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("*.SV.vcf.gz"), file("*.SV.vcf.gz.tbi")

    script:

      def inBamStr = bam
          .withIndex()
          .collect { bam, idx ->
              "--bam ${bam}"
          }
          .join(' ')

      """
      mkdir manta_rundir

      configManta.py \
        --reference ${fasta} \
        --runDir manta_rundir \
        --callRegions ${mantaBed} \
        ${inBamStr}
      sed -i "s/smtplib\\.SMTP('localhost')/smtplib.SMTP('localhost', timeout=2)/" manta_rundir/runWorkflow.py
      python manta_rundir/runWorkflow.py -j ${task.cpus} -m local -g 100
      mv manta_rundir/results/variants/diploidSV.vcf.gz ${id.join("-")}.SV.vcf.gz
      mv manta_rundir/results/variants/diploidSV.vcf.gz.tbi ${id.join("-")}.SV.vcf.gz.tbi

      """

}
