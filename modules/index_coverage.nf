process INDEX_COVERAGE {
    tag "batch_${id[0]}"
    cpus 1
    // publishDir("${params.batchDir}/r04_metrics", mode: 'copy', overwrite: true, failOnError: true)
    container 'docker://amazoncorretto:21.0.7'
    containerOptions "-B ${params.javaDir} -B ${params.base} -B ${params.batchDir} -B ${params.rsync}"
    input:
      tuple val(id), val(sex), file(coverage)
      file(control)
    output:
      tuple val(id), val(sex), file("Coverage.indexed")
    script:
      """
      #!/usr/bin/env bash
      java \\
        -Xmx1g \\
        -XX:ParallelGCThreads=1 \\
        -XX:ConcGCThreads=1 \\
        -cp ${params.javaDir} \\
        IndexedCoverageFile2NF \\
        ${coverage} \\
        ${control} \\
        ${params.base}/resources/grch38-v2-pipeline/variantcall.bed \\
        > Coverage.indexed

        DEST_DIR="${params.batchDir}/r04_metrics"
        mkdir -p "\$DEST_DIR"

        SRC_FILE="Coverage.indexed"
        TMP_FILE=".Coverage.indexed.partial.\$\$"

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