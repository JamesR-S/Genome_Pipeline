process CALL_HLA_VARIANTS {
    tag "${id}"
    cpus 16

    errorStrategy 'retry'
    maxRetries 3

    time { 
      def t = 36.h * (1 << (task.attempt - 1))
      t > 108.h ? 108.h : t
    }

    container 'docker://jamescraufurd/deepvariant:1.9.0-hla'
    containerOptions("-B /usr/lib/locale/:/usr/lib/locale/ -B ${params.batchDir} -B ${params.rsync} -B ${params.chr6_fasta} -B ${params.chr6_fasta}.fai")  
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(bam), file(bai)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${id}_hla.g.vcf.gz"), file("${id}_hla.g.vcf.gz.csi"), emit: gvcf 
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${id}_hla.vcf.gz"), file("${id}_hla.vcf.gz.csi"), emit: vcf
    script:
      """

      mkdir -p \$PWD/temp
      export TMPDIR=\$PWD/temp

      /opt/deepvariant/bin/run_deepvariant \
        --model_type=WGS \
        --ref=${params.chr6_fasta} \
        --reads=${bam} \
        --regions="chr6:25726063-33400644" \
        --output_gvcf=${id}_hla.g.vcf.gz \
        --output_vcf=${id}_hla.vcf.gz \
        --num_shards=16 \
        --vcf_stats_report=true

        bcftools index ${id}_hla.g.vcf.gz
        bcftools index ${id}_hla.vcf.gz

      DEST_DIR="${params.batchDir}/r04_hla_vcfs"
      mkdir -p "\$DEST_DIR"

      STAGE_DIR="\$DEST_DIR/.stage.${id}.\$\$"
      rm -rf "\$STAGE_DIR"
      mkdir -p "\$STAGE_DIR/.partial"

      FILES=( "${id}_hla.g.vcf.gz" "${id}_hla.g.vcf.gz.csi" "${id}_hla.vcf.gz" "${id}_hla.vcf.gz.csi" )

      for f in "\${FILES[@]}"; do
        [[ -s "\$f" ]] || { echo "Missing/empty output: \$f" >&2; exit 1; }
      done

      attempts=5
      delay=10
      ok=0

      for i in \$(seq 1 \$attempts); do
        # clean stage between attempts
        rm -f "\$STAGE_DIR/"* 2>/dev/null || true
        mkdir -p "\$STAGE_DIR/.partial"

        if ${params.rsync} -a --no-g --checksum --delay-updates \\
            --partial --partial-dir=".partial" \\
            "\${FILES[@]}" "\$STAGE_DIR/"; then
          ok=1
          break
        fi

        echo "rsync to stage failed (attempt \$i/\$attempts) — retrying in \${delay}s" >&2
        sleep "\$delay"
      done

      [[ "\$ok" -eq 1 ]] || { echo "Publish failed: rsync never succeeded" >&2; exit 1; }

      for f in "\${FILES[@]}"; do
        [[ -s "\$STAGE_DIR/\$f" ]] || { echo "Stage missing/empty: \$STAGE_DIR/\$f" >&2; exit 1; }
      done

      # Promote data files
      for f in "\${FILES[@]}"; do
        mv -f "\$STAGE_DIR/\$f" "\$DEST_DIR/\$f"
      done

      rm -rf "\$STAGE_DIR"

      """
}