#!/usr/bin/env nextflow
process PARLIAMENT2 {
    cpus 16
    tag { id }
    container 'jamescraufurd/parliament2:latest'
    containerOptions("-B /usr/lib/locale/:/usr/lib/locale/ -B \$PWD:/home/dnanexus/in -B \$PWD:/home/dnanexus/out")
    publishDir(path: { "${params.batchDir}/r04_parliament2" },
        mode: 'copy')

    input:
      tuple val(id), val(sex), val(trio), val(family), val(famSampleCount), file(bam), file(bai)
      file(fasta)
      file(fai)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("*combined.genotyped.vcf")
    script:

      """

      python /home/dnanexus/parliament2.py \
      --bam ${bam} \
      --bai ${bai} \
      --ref_genome ${fasta} \
      --fai ${fai} \
      --prefix ${id} \
      --filter_short_contigs \
      --breakdancer \
      --breakseq \
      --manta \
      --breakseq \
      --lumpy \
      --cnvnator \
      --delly_deletion \
      --delly_inversion \
      --delly_duplication \
      --delly_insertion \
      --genotype

      """

}
