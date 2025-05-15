process PARABRICKS_DV_VCF {
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
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${id}.vcf")
    script:
      """
      pbrun deepvariant \
        --ref ${Fasta} \
        --in-bam ${bam} \
        --consider-strand-bias \
        --out-variants ${id}.vcf 
      """
}