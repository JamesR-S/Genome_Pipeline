process DEEP_VARIANT {
    tag "${id}"
    cpus 16

    errorStrategy 'retry'
    maxRetries 3

    time { 
      def t = 36.h * (1 << (task.attempt - 1))
      t > 108.h ? 108.h : t
    }

    container 'docker://google/deepvariant:1.9.0'
    containerOptions('-B /usr/lib/locale/:/usr/lib/locale/')
    publishDir (
    path: "${params.batchDir}",
    mode: 'copy',
    overwrite: true,
    saveAs: { fn ->                        
        fn.endsWith('.g.vcf.gz') ? "r04_gvcfs/${fn}" :
        fn.endsWith('.g.vcf.gz.csi') ? "r04_gvcfs/${fn}" :
        "r04_vcfs/${fn}"
    }
)
    
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(bam), file(bai)
      file(Fasta)
      file(Fai)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${id}.g.vcf.gz"), file("${id}.g.vcf.gz.csi"), emit: gvcf 
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${id}.vcf.gz"), file("${id}.vcf.gz.csi"), emit: vcf
    script:
      """

      mkdir -p \$PWD/temp
      export TMPDIR=\$PWD/temp

      /opt/deepvariant/bin/run_deepvariant \
        --model_type=WGS \
        --ref=${Fasta[0]} \
        --reads=${bam} \
        --output_gvcf=${id}.g.vcf.gz \
        --output_vcf=${id}.vcf.gz \
        --num_shards=16 \
        --vcf_stats_report=true

        bcftools index ${id}.g.vcf.gz
        bcftools index ${id}.vcf.gz
      """
}