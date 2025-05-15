process PARABRICKS_DV_GVCF {
    tag "${id}"
    cpus 8
    queue 'gpu'
    clusterOptions '--gres=gpu:1'
    container 'nvcr.io/nvidia/clara/clara-parabricks:4.5.0-1'
    containerOptions('--nv -B /usr/lib/locale/:/usr/lib/locale/')
    
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(bam), file(bai)
      file(Fasta)
      file(Fai)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${id}.g.vcf.gz")
    script:
      """
      pbrun deepvariant \
        --ref ${Fasta} \
        --in-bam ${bam} \
        --gvcf \
        --consider-strand-bias \
        --out-variants ${id}.g.vcf.gz 
      """
}