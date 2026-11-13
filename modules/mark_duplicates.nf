process MARKDUP {
  cpus 16
  //publishDir "${params.batchDir}/r04_assembly", mode: 'copy', overwrite: true, failOnError: true
  tag "${id}"
  module 'SAMtools/1.22.1-GCC-14.2.0'

  input:
    tuple val(id), val(sex), val(family), val(trio),
          val(famSampleCount), file(fxbam)

  output:
      tuple val(id), val(sex), val(family), val(trio),
            val(famSampleCount),
            path("${id}.bam"), path("${id}.bam.bai"),
            emit: bam

      tuple val(id), val(sex), val(family), val(trio),
            val(famSampleCount),
            path("${id}.cram"), path("${id}.cram.crai"),
            emit: cram

  script:
  """
  set -euo pipefail
  mkdir -p tmp

  tmp="${id}.tmp.bam"
  trap 'rm -f \$tmp' EXIT

  ${params.fastdup} --input "${fxbam}" \
        --output "\$tmp" \
        --metrics "${id}.dup_metrics.txt" \
        --num-threads ${task.cpus}

  # Preserve the deduplicated BAM
  mv "\$tmp" ${id}.bam

  # Index it for downstream analysis
  samtools index -@ ${task.cpus} ${id}.bam

  # Generate the archival CRAM from the same BAM
  samtools view \
        -@ ${task.cpus} \
        -T "${params.referenceFasta}" \
        -O cram \
        -o ${id}.cram \
        ${id}.bam

  samtools index -@ ${task.cpus} ${id}.cram

  DEST_DIR="${params.batchDir}/r04_assembly"
  mkdir -p "\$DEST_DIR"

  STAGE_DIR="\$DEST_DIR/.stage.${id}.\$\$"
  rm -rf "\$STAGE_DIR"
  mkdir -p "\$STAGE_DIR/.partial"

  FILES=( "${id}.cram" "${id}.cram.crai" )

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
