process XTEA {
    tag "${id}"
    container 'jamesrusssilsby/exetea:latest'
    
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
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${id}.g.vcf.gz"), file("${id}.g.vcf.gz.csi"), emit: gvcf 
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${id}.vcf.gz"), file("${id}.vcf.gz.csi"), emit: vcf
    script:
      """
      cat >> ${family}_bams.tsv << 'EOF'
      ${ id.withIndex().collect { idx, sid ->
        "${sid}\\t${bam[idx]}"
      }.join('\\n')}
      EOF

      cat >> ${family}_samples.tsv << 'EOF'
      ${ id.withIndex().collect { idx, sid ->
        "${sid}" }.join('\\n')}
      EOF


      cat ${family}_bams.tsv
      cat ${family}_samples.tsv

       xtea \
       -i ${family}_samples.tsv \
       -b ${family}_bams.tsv \
       -x null \
       -p . \
       -o submit_jobs.sh \
       -l /home/rep_lib_annotation/ \
       -r ${Fasta[0]} \
       -g ${GFF} \
       --xtea /home/ec2-user/xTea/xtea/ \
       -f 5907 \
       -y 15
      """
}