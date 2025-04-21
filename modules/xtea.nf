process XTEA {
    tag "${id}"
    container 'jamesrusssilsby/exetea:0.1.9d'
    containerOptions " -B ${params.xtea_libraries}"
    cpus 16
    publishDir(
        path: { "r04_transposable_elements" },
        pattern: "*.vcf*",
        mode: 'copy')
    
    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(bam), file(bai)
      file(Fasta)
      file(Fai)
      file(GFF)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("*.g.vcf.gz"), file("*.g.vcf.gz.csi"), emit: gvcf 
      tuple val(id), val(sex), val(family), val(famSampleCount), file("*.vcf.gz"), file("*.vcf.gz.csi"), emit: vcf
    script:
      """
      cat >> ${family}_bams.tsv << 'EOF'
      ${ id.withIndex().collect { sid, idx ->
        "${sid}\t${sid}.bam"
      }.join('\n')}
      EOF

      cat >> ${family}_samples.tsv << 'EOF'
      ${ id.withIndex().collect { sid, idx ->
        "${sid}" }.join('\n')}
      EOF

      cat ${family}_bams.tsv
      cat ${family}_samples.tsv

       /data/xTea/bin/xtea \
       -i ${family}_samples.tsv \
       -b ${family}_bams.tsv \
       -x null \
       -p \$PWD \
       -o jobs.sh \
       -l ${params.xtea_libraries} \
       -r ${Fasta[0]} \
       -g ${GFF} \
       --xtea /data/xTea/xtea/ \
       -f 63 \
       -y 15

      sed -n 's/^sbatch[[:space:]]*<[[:space:]]*\\(.*\\)\$/\\1/p' jobs.sh \
      | parallel -j16 'bash < {}'
      """
}