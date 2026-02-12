#!/usr/bin/env nextflow
process PARLIAMENT2 {
    cpus 16
    tag { id }
    container 'jamescraufurd/parliament2:latest'
    containerOptions("-B /usr/lib/locale/:/usr/lib/locale/ -B \$PWD:/home/dnanexus/in -B \$PWD:/home/dnanexus/out  -B ${params.batchDir} -B ${params.rsync}")
    // publishDir(path: { "${params.batchDir}/r04_parliament2" },
    //    mode: 'copy', overwrite: true, failOnError: true)

    input:
      tuple val(id), val(sex), val(trio), val(family), val(famSampleCount), file(bam), file(bai)
      file(fasta)
      file(fai)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("*combined.genotyped.vcf")
    script:

      """

      python /home/dnanexus/parliament2.py \
      --bam ${bam} \
      --bai ${bai} \
      --ref_genome ${fasta} \
      --fai ${fai} \
      --prefix ${id} \
      --filter_short_contigs \
      --breakdancer \
      --breakseq \
      --manta \
      --breakseq \
      --lumpy \
      --cnvnator \
      --delly_deletion \
      --delly_inversion \
      --delly_duplication \
      --delly_insertion \
      --genotype

      DEST_DIR="${params.batchDir}/r04_parliament2"
      mkdir -p "\$DEST_DIR"

      STAGE_DIR="\$DEST_DIR/.stage.${id}.\$\$"
      rm -rf "\$STAGE_DIR"
      mkdir -p "\$STAGE_DIR/.partial"

      FILES=( *combined.genotyped.vcf )

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
