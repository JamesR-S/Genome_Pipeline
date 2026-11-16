process RUST_COVERAGE {
    tag "batch_${id[0]}"
    cpus 16
    memory 240.GB
    module 'Clang/17.0.6-GCCcore-13.2.0'

    // Keep the BAMs on the shared filesystem. Copying 50 whole-genome BAMs
    // to node scratch could dominate the actual coverage calculation.
    scratch false

    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), path(bam), path(bai)
      path(control)
      path(target_intervals)
      path(rust_bin, name: 'coverage-rs')
      path(metadata_java, name: 'CompatMetadata.java')

    output:
      tuple val(id), val(sex), path('Coverage.indexed')

    script:
      def bamArgs = bam.collect { "'${it.name}'" }.join(' ')
      def mapq = params.coverageMinMapq != null ? params.coverageMinMapq : 30
      def window = params.coverageQueryWindow != null ? params.coverageQueryWindow : 128000
      // Older fast binaries predate --reader-mode; use 'legacy' to omit it.
      def readerArg = params.coverageRustReaderMode == 'legacy' ? '' : '--reader-mode thread-local'
      """
      set -euo pipefail

      # Use the Nextflow work directory for temporary files
      mkdir -p "\$PWD/java_tmp"
      export TMPDIR="\$PWD/java_tmp"

      # Apply JVM options to Java launched by Rust
      export JAVA_TOOL_OPTIONS="-Djava.io.tmpdir=\$PWD/java_tmp -XX:-UsePerfData"
      javac -d . CompatMetadata.java
      # Keep sample order identical to ch_collapsed (sorted by sample id).
      printf '%s\\n' ${bamArgs} > samples.list

      # HTSlib accepts <bam>.bai. Nextflow may stage the source BAI files as
      # WG0007.bai rather than WG0007.bam.bai; link both names locally.
      while IFS= read -r bam_path; do
          [[ -n "\$bam_path" ]] || continue
          if [[ ! -e "\${bam_path}.bai" ]]; then
              existing_index="\${bam_path%.bam}.bai"
              if [[ ! -e "\$existing_index" ]]; then
                  echo "Missing BAI index for \$bam_path (looked for \$existing_index)" >&2
                  exit 1
              fi
              ln -s "\$existing_index" "\${bam_path}.bai"
          fi
      done < samples.list

      # Some clusters default to a low open-file limit. The fast reader mode
      # can open up to task.cpus * sample-count indexed BAM handles.
      ulimit -n 4096 2>/dev/null || true

      ./coverage-rs build \\
          -L '${target_intervals}' \\
          -I samples.list \\
          --control '${control}' \\
          --threads ${task.cpus} \\
          --min-mapq ${mapq} \\
          --query-window ${window} ${readerArg} \\
          --java-dir . \\
          -o Coverage.indexed

      # Preserve the existing publish contract, copying to a temporary name
      # before atomically renaming the completed file in r04_metrics.
      DEST_DIR='${params.batchDir}/r04_metrics'
      mkdir -p "\$DEST_DIR"
      DEST_TMP="\$DEST_DIR/.Coverage.indexed.partial.\$\$"
      published=0
      for attempt in 1 2 3 4 5; do
          if ${params.rsync} -a --no-g --checksum --delay-updates --partial \\
              Coverage.indexed "\$DEST_TMP"; then
              mv -f "\$DEST_TMP" "\$DEST_DIR/Coverage.indexed"
              published=1
              break
          fi
          rm -f "\$DEST_TMP"
          echo "Coverage publish failed (attempt \$attempt/5); retrying" >&2
          sleep 10
      done
      if [[ "\$published" != 1 ]]; then
          echo 'Failed to publish Coverage.indexed after five attempts' >&2
          exit 1
      fi
      """
}
