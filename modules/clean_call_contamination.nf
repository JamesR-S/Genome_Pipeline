#!/usr/bin/env nextflow
process CONTAM {
    tag "${id}"
    module 'SAMtools/1.17-GCC-12.2.0'
    module 'BCFtools/1.17-GCC-12.2.0'
    publishDir "${params.batchDir}/r04_metrics", mode: 'copy', overwrite: true, failOnError: true
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(bam), file(bai)
    output:
      tuple val(id), file("${id}_cleanCall.csv")
    script:
      """
      samtools view -q 20 -F 0x0704 -uh ${bam}  | samtools calmd -AEur - ${params.referenceFasta} |  samtools mpileup  -s -O -f ${params.referenceFasta} -d 255 -l ${params.resourcesDir}/ExAC.r0.1.sites.vep.AF5.liftover_b38.vcf - | bgzip -c > cleanCall.pileup.${id}.txt.gz
      tabix -f -s 1 -b 2 -e 2 cleanCall.pileup.${id}.txt.gz
      ${params.software}/cleancall/bin/cleanCall verify --vcf ${params.resourcesDir}/ExAC.r0.1.sites.vep.AF5.liftover_b38.vcf --minAF 0.01 --minCallRate 0.95 --out cleanCall.verify.${id} --mpu cleanCall.pileup.${id}.txt.gz --smID ${id} --maxDepth 20
      mv cleanCall.verify.${id}.selfSM ${id}_cleanCall.csv
      """
}

process CONTAM_SMALL {
    tag "${id}"
    cpus 16
    module 'SAMtools/1.17-GCC-12.2.0'
    module 'BCFtools/1.17-GCC-12.2.0'
    // publishDir "${params.batchDir}/r04_metrics", mode: 'copy', overwrite: true, failOnError: true
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(bam), file(bai)
    output:
      tuple val(id), file("${id}_cleanCall.csv")
    script:
      """
      samtools view -@16 -q 20 -F 0x0704 -uh ${id}.bam chr2 | samtools calmd -@16 -AEur - ${params.referenceFasta} |  samtools mpileup -@ 16 -s -O -f ${params.referenceFasta} -d 255 -l ${params.resourcesDir}/ExAC.r0.1.sites.vep.AF5.chr2.giab.liftover_b38.bed - | bgzip -c > cleanCall_small.pileup.${id}.txt.gz
      tabix -f -s 1 -b 2 -e 2 cleanCall_small.pileup.${id}.txt.gz
      ${params.software}/cleancall/bin/cleanCall verify --vcf ${params.resourcesDir}/ExAC.r0.1.sites.vep.AF5.chr2.giab.liftover_b38.vcf --minAF 0.01 --minCallRate 0.95 --out cleanCall_small.verify.${id} --mpu cleanCall_small.pileup.${id}.txt.gz --smID ${id} --maxDepth 20
      mv cleanCall_small.verify.${id}.selfSM ${id}_cleanCall.csv

      DEST_DIR="${params.batchDir}/r04_metrics"
      mkdir -p "\$DEST_DIR"

      SRC_FILE="${id}_cleanCall.csv"
      TMP_FILE=".${id}_cleanCall.csv.partial.\$\$"

      attempts=5
      delay=10

      for i in \$(seq 1 \$attempts); do
        # copy to temp name first
        if ${params.rsync} -a --checksum --delay-updates --partial \
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
