process XY_COVERAGE {
    tag "batch_${ids[0]}-${ids[-1]}"
    cpus 1
    publishDir("${params.batchDir}/r04_metrics", mode: 'copy', overwrite: true, failOnError: true)
    container 'docker://amazoncorretto:21.0.7'
    containerOptions "-B ${params.javaDir} -B ${params.gatkJar} -B ${params.xy_bitmap} -B ${params.batchDir} -B ${params.rsync}"    
    input:
      tuple val(ids), val(sex), file(coverageBinner)
    output:
      tuple val(ids), val(sex), file("XY_coverage")
    script:
      """

      id_flags="${ ids.withIndex()
                     .findAll { id, idx ->
                         def s = sex[idx]?.toUpperCase()
                         s == 'MALE' || s == 'FEMALE'
                     }
                     .collect { id, idx ->
                         sex[idx].equalsIgnoreCase('MALE') ? "-m ${id}" : "-f ${id}"
                     }
                     .join(' ') }"

      java -Xmx1g -XX:ParallelGCThreads=1 -XX:ConcGCThreads=1 -cp ${params.javaDir}:${params.javaDir}/jars/htsjdk-4.2.0.jar XYCoverageBinned \\
       -bitmap ${params.xy_bitmap} \\
        -v genome \\
        \$id_flags \\
        *.coverageBinner \\
        > XY_coverage

      DEST_DIR="${params.batchDir}/r04_metrics"
      mkdir -p "\$DEST_DIR"

      SRC_FILE="XY_coverage"
      TMP_FILE=".XY_coverage.partial.\$\$"

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