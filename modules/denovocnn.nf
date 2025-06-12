process DENOVOCNN {
    tag { trio_ids.join('-') }
    cpus 16
    container 'docker://jamesrusssilsby/denovocnn:latest'
    containerOptions('-B /usr/lib/locale/:/usr/lib/locale/')
    
    publishDir "${params.batchDir}/r04_denovocnn", mode: 'copy'
    
    input:
      tuple val(id), val(trio_ids), file(bam), file(bai), file(vcf), file(csi)
      file(Fasta)
      file(Fai)
      file(gnomad_snps)
      file(gnomad_snp_idx)
    output:
      tuple val(id), val(trio_ids), file("${trio_ids.join('-')}_denovos.filtered.txt")
    script:
      """
      bcftools view -f PASS ${vcf[0]} -Oz -o filtered.vcf.gz
      bcftools index filtered.vcf.gz

      bcftools isec -C filtered.vcf.gz ${vcf[1]} ${vcf[2]} ${gnomad_snps} > all_variants.txt
      split -d -n l/16 -a 2 --additional-suffix=.txt all_variants.txt part_variants

      parallel --jobs \$(nproc) "
      echo 'Processing {}' ; \
      /app/apply_denovocnn.sh \
        -w=\${PWD} \
        -g=${Fasta[0]} \
        --variant-list={} \
        -cb=${bam[0]} \
        -fb=${bam[1]} \
        -mb=${bam[2]} \
        -sm=/app/models/snp \
        -im=/app/models/ins \
        -dm=/app/models/del \
        -o=predictions_{/.}.csv \
      " ::: part_variants*.txt

      (head -n1 predictions_part_variants00.csv &&  \
      tail -q -n +2 predictions_part_variants*.csv) \
      | awk '\$5 >= 0.5' > ${trio_ids.join('-')}_denovos.filtered.txt

        
      """
}