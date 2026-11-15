process DENOVOCNN {
    tag { trio_ids.join('-') }
    cpus 16
    memory '224 GB'
    container 'docker://jamesrusssilsby/denovocnn:latest'
    containerOptions("-B /usr/lib/locale/:/usr/lib/locale/ -B ${params.resourcesDir} -B ${params.batchDir} -B ${params.rsync}${params.familyMode ? " -B ${params.familySourceRoot}" : ""}")
    
    // publishDir "${params.batchDir}/r04_denovocnn", mode: 'copy', overwrite: true, failOnError: true
    
    input:
      tuple val(id), val(trio_ids), file(bam), file(bai), file(vcf), file(csi)
      file(Fasta)
      file(Fai)
      file(gnomad_snps)
      file(gnomad_snp_idx)
    output:
      tuple val(id), val(trio_ids), file("${trio_ids.join('-')}_denovos.filtered.txt")
    script:

      def minChildDP = 8
      def minChildGQ = 10
      if (minChildDP < 0 || minChildGQ < 0) {
          error "minProbandDP and minProbandGQ must be non-negative"
      }
      def childFilter = '(GT="het" || ((CHROM="X" || CHROM="Y" || CHROM="chrX" || CHROM="chrY") && GT="alt"))' +
                        ' && FMT/DP>=' + minChildDP + ' && FMT/GQ>=' + minChildGQ

      """
      export OMP_NUM_THREADS=1
      export MKL_NUM_THREADS=1
      export TF_NUM_INTRAOP_THREADS=1
      export TF_NUM_INTEROP_THREADS=1

      PRIMARY=\$(bcftools index -s "${vcf[0]}" \
          | awk '\$1 ~ /^(chr)?([1-9]|1[0-9]|2[0-2]|X|Y)\$/ {print \$1}' \
          | paste -sd, -)
      if [[ -z "\$PRIMARY" ]]; then
          echo "No primary chromosomes found in ${vcf[0]}" >&2
          exit 1
      fi

      bcftools view -f PASS -r "\$PRIMARY" -T ${params.easyRegions} --targets-overlap pos -i '${childFilter}' ${vcf[0]} -Oz -o filtered.vcf.gz
      bcftools index filtered.vcf.gz

      bcftools isec -C -c none filtered.vcf.gz ${vcf[1]} ${vcf[2]} ${params.gnomadCommon} > all_variants.txt
      split -e -d -n l/16 -a 2 \
      --additional-suffix=.txt \
      all_variants.txt part_variants

      parallel --jobs 16 "
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
        -t=1 \
      " ::: part_variants*.txt

      (head -n1 predictions_part_variants00.csv &&  \
      tail -q -n +2 predictions_part_variants*.csv) \
      | awk '\$5 >= 0.5' > ${trio_ids.join('-')}_denovos.filtered.txt

      DEST_DIR="${params.batchDir}/r04_denovocnn"
      mkdir -p "\$DEST_DIR"

      SRC_FILE="${trio_ids.join('-')}_denovos.filtered.txt"
      TMP_FILE=".${trio_ids.join('-')}_denovos.filtered.txt.partial.\$\$"

      attempts=5
      delay=10

      for i in \$(seq 1 \$attempts); do
        # copy to temp name first
        if ${params.rsync} -a --no-g --checksum --delay-updates --partial \
            "\$SRC_FILE" "\$DEST_DIR/\$TMP_FILE" ; then
          # then rename into place
          mv -f "\$DEST_DIR/\$TMP_FILE" "\$DEST_DIR/\$SRC_FILE"
          break
        fi
        echo "rsync failed (attempt \$i/\$attempts) — retrying in \${delay}s" >&2
        sleep "\$delay"
      done

      # if temp still exists, we never successfully promoted to final name
      if [[ -e "\$DEST_DIR/\$TMP_FILE" ]]; then
        echo "Publish failed: temp file still present: \$DEST_DIR/\$TMP_FILE" >&2
        exit 1
      fi
        
      """
}
