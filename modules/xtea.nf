process XTEA {
    tag "${family}"
    container 'jamesrusssilsby/exetea:0.1.9d'
    containerOptions " -B ${params.xtea_libraries} -B ${params.batchDir} -B ${params.rsync}"
    cpus 16
    // publishDir(
    //     path: { "${params.batchDir}/r04_transposable_elements" },
    //     pattern: "*.vcf*",
    //     mode: 'copy', 
    //     overwrite: true, 
    //     failOnError: true)
    
    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(bam), file(bai)
      file(Fasta)
      file(Fai)
      file(GFF)
    output:

      tuple val(id), val(sex), val(family), val(famSampleCount), file("*.vcf"), emit: vcf
    script:
      """

      declare -a ids=( ${id.join(" ")} )

      for i in "\${ids[@]}"
      do
        echo -e "\${i}" >> ${family}_samples.tsv
        echo -e "\${i}\\t\${i}.bam" >> ${family}_bams.tsv
      done

      cat ${family}_bams.tsv
      cat ${family}_samples.tsv

       ${params.xtea_libraries}xtea \
       -i ${family}_samples.tsv \
       -b ${family}_bams.tsv \
       -x null \
       -p \$PWD \
       -o jobs.sh \
       -l ${params.xtea_libraries}rep_lib_annotation/ \
       -r ${Fasta[0]} \
       -g ${GFF} \
       --xtea /data/xTea/xtea/ \
       -f 5907 \
       -y 7

      sed -n 's/^sbatch[[:space:]]*<[[:space:]]*\\(.*\\)\$/\\1/p' jobs.sh \
      | parallel -j16 'bash < {}'

      for file in WG*/*/*.vcf; do grep -v "orphan" \$file > \$(basename \$file); done

    DEST_DIR="${params.batchDir}/r04_transposable_elements"
    mkdir -p "\$DEST_DIR"

    STAGE_DIR="\$DEST_DIR/.stage.${id}.\$\$"
    rm -rf "\$STAGE_DIR"
    mkdir -p "\$STAGE_DIR/.partial"

    FILES=( *.vcf* )

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