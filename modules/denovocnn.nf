process DENOVOCNN {
    tag { trio_ids.join('-') }
    cpus 16
    container 'docker://jamesrusssilsby/denovocnn:latest'
    containerOptions('-B /usr/lib/locale/:/usr/lib/locale/')
    
    publishDir "r04_denovocnn", mode: 'copy'
    
    input:
      tuple val(id), val(trio_ids), file(bam), file(bai), file(vcf), file(csi)
      file(Fasta)
      file(Fai)
      file(gnomad_snps)
      file(gnomad_snp_idx)
    output:
      tuple val(id), val(trio_ids), file("*_proband.vcf.gz"),file("*_father.vcf.gz"),file("*_mother.vcf.gz"), file("*_proband.vcf.gz.csi"),file("*_father.vcf.gz.csi"),file("*_mother.vcf.gz.csi")
    script:
      """
      bcftools isec -C ${vcf[0]} ${vcf[1]} ${vcf[2]} ${gnomad_snps} > all_variants.txt
      split -d -l 10000 --additional-suffix=.txt all_variants.txt part_variants

      parallel --bar --jobs \$(nproc) '
      /app/apply_denovocnn.sh \
        --workdir='"\$PWD"'' \
        --ref=${Fasta[0]} \
        -v {} \
        --child-bam=${bam[0]} \
        --father-bam=${bam[1]} \
        --mother-bam=${bam[2]} \
        --snp-model=/app/models/snp \
        --in-model=/app/models/ins \
        --del-model=/app/models/del \
        -o    predictions_{/.}.csv
      ' ::: part_variants*.txt

      (head -n1 predictions_part_variants00.csv &&  \
      tail -q -n +2 predictions_part_variants*.csv) \
        > ${trio_ids.join('-')}_denovos.filtered.txt

        
      """
}