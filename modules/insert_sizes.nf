process INSERT_SIZES {
    tag "${id}"
    cpus 2
    // publishDir("${params.batchDir}/r04_metrics", mode: 'copy', overwrite: true, failOnError: true)
    
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(bam), file(bai)
    output:
      tuple val(id), val(sex), file("${id}.insertSize.histogram"), file("${id}.insertSize.stats")
    script:
      """
      java -Xmx5g -XX:ParallelGCThreads=2 -XX:ConcGCThreads=2 -cp ${params.javaDir}:${params.gatkJar} InsertSizeHistogram \\
        ${bam} \\
        chr1 \\
        80000000 \\
        100000000 \\
        > ${id}.insertSize.histogram 2> ${id}.insertSize.stats


        DEST_DIR="${params.batchDir}/r04_metrics"
        mkdir -p "\$DEST_DIR"

        STAGE_DIR="\$DEST_DIR/.stage.${id}.\${NXF_TASK_ID}.\$\$"
        rm -rf "\$STAGE_DIR"
        mkdir -p "\$STAGE_DIR/.partial"

        FILES=( "${id}.insertSize.histogram" "${id}.insertSize.stats" )

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

          if ${params.rsync} -a --checksum --delay-updates \\
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