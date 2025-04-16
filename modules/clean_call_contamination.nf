#!/usr/bin/env nextflow
process CONTAM {
    tag "${id}"
    module 'SAMtools/1.17-GCC-12.2.0'
    publishDir "r03_metrics", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(bam), file(bai)
    output:
      tuple val(id), file("${id}_cleanCall.csv")
    script:
      """
      samtools view -q 20 -F 0x0704 -uh ${bam}  | samtools calmd -AEur - ${params.referenceFasta} |  samtools mpileup  -s -O -f ${params.referenceFasta} -d 255 -l ${params.resourcesDir}/ExAC.r0.1.sites.vep.AF5.liftover_b38.vcf - | bgzip -c > cleanCall.pileup.${id}.txt.gz
      tabix -f -s 1 -b 2 -e 2 r03_metrics/cleanCall.pileup.${id}.txt.gz
      ${params.software}/cleancall/bin/cleanCall verify --vcf ${params.resourcesDir}/ExAC.r0.1.sites.vep.AF5.liftover_b38.vcf --minAF 0.01 --minCallRate 0.95 --out cleanCall.verify.${id} --mpu cleanCall.pileup.${id}.txt.gz --smID ${id} --maxDepth 20
      mv cleanCall.verify.${id}.selfSM ${id}_cleanCall.csv
      """
}

process CONTAM_SMALL {
    tag "${id}"
    module 'SAMtools/1.17-GCC-12.2.0'
    publishDir "r03_metrics", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(bam), file(bai)
    output:
      tuple val(id), file("${id}_cleanCall_small.csv")
    script:
      """
      samtools view -q 20 -F 0x0704 -uh r03_assembly/${id}.bam 2 | samtools calmd -AEur - ${params.referenceFasta} |  samtools mpileup  -s -O -f ${params.referenceFasta} -d 255 -l ${params.resourcesDir}/ExAC.r0.1.sites.vep.AF5.chr2.giab.liftover_b38.vcf - | bgzip -c > cleanCall_small.pileup.${id}.txt.gz
      tabix -f -s 1 -b 2 -e 2 r03_metrics/cleanCall_small.pileup.${id}.txt.gz
      ${params.software}/cleancall/bin/cleanCall verify --vcf ${params.resourcesDir}/ExAC.r0.1.sites.vep.AF5.chr2.giab.liftover_b38.vcf --minAF 0.01 --minCallRate 0.95 --out cleanCall_small.verify.${id} --mpu cleanCall_small.pileup.${id}.txt.gz --smID ${id} --maxDepth 20
      mv cleanCall_small.verify.${id}.selfSM ${id}_cleanCall_small.csv
      """
}
