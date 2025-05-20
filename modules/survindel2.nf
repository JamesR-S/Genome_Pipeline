#!/usr/bin/env nextflow
process SURVINDEL2 {
    cpus 16
    tag { id }
    container 'jamescraufurd/survindel2:latest'
    containerOptions("-B /usr/lib/locale/:/usr/lib/locale/ -B ${params.survindel2model}")
    publishDir(path: { "${params.batchDir}/r04_survindel2" },
        mode: 'copy')

    input:
      tuple val(id), val(sex), val(trio), val(family), val(famSampleCount), file(bam), file(bai)
      file(fasta)
      file(fai)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${id}.survindel.cnv.vcf.gz")
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${id}.survindel.pass-ml.cnv.vcf.gz")
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${id}.genotyped.cnv.vcf.gz")
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${id}.genotyped.pass-ml.cnv.vcf.gz")

    script:

      """
      mkdir survindel_rundir
      mkdir survtyper_base_rundir
      mkdir survtyper_ml_rundir

      python3 /survindel2/survindel2.py \
      --threads 16 \
      ${bam} \
      survindel_rundir \
      ${fasta}

      python3 /survindel2/run_classifier.py \
      survindel_rundir/out.vcf.gz \
      survindel_rundir/out.pass-ml.vcf.gz \
      survindel_rundir/stats.txt \
      ALL \
      ${params.survindel2model}

      mv survindel_rundir/out.pass.vcf.gz ${id}.survindel.cnv.vcf.gz
      mv survindel_rundir/out.pass-ml.vcf.gz ${id}.survindel.pass-ml.cnv.vcf.gz

      python3 /survtyper/survtyper.py \
      --threads 16 \
      ${id}.survindel.cnv.vcf.gz \
      ${bam} \
      survtyper_base_rundir \
      ${fasta}

      python3 /survtyper/survtyper.py \
      --threads 16 \
      ${id}.survindel.pass-ml.cnv.vcf.gz \
      ${bam} \
      survtyper_ml_rundir \
      ${fasta}

      mv survtyper_base_rundir/genotyped.vcf.gz ${id}.genotyped.cnv.vcf.gz
      mv survtyper_ml_rundir/genotyped.vcf.gz ${id}.genotyped.pass-ml.cnv.vcf.gz

      """

}
