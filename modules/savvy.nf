#!/usr/bin/env nextflow
process HOMOZYGOSITY {
    tag "${family}"
    publishDir "r04_metrics", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(vcf), file(csi)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("*_homozygosity.csv")
    script:
      """
      zcat ${vcf} > \$(basename ${vcf} .gz)
      ids=( ${id.join(" ")} )
      for i in \${ids[@]}; do
           java -Xmx9g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -cp ${params.javaDir}:${params.gatkJar} VcfToHomozygosity7 \$(basename ${vcf} .gz) \$i > \${i}_homozygosity.csv
      done
      rm \$(basename ${vcf} .gz)      
      """
}

process SHARED_HAPLOTYPES {
    tag "${family}"
    publishDir "r04_metrics", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(vcf), file(csi)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("*_homozygosity.csv")
    script:
      """
      zcat ${vcf} > \$(basename ${vcf} .gz)
      ids=( ${id.join(" ")} )
      for (( i=0;            i < \${#ids[@]}; i++ )); do       
        for (( j=i+1;      j < \${#ids[@]}; j++ )); do  
           java -Xmx9g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -cp ${params.javaDir}:${params.gatkJar} VcfToHomozygosity7 \$(basename ${vcf} .gz) -p \${ids[i]} \${ids[j]} > \${ids[i]}_\${ids[j]}_homozygosity.csv
      done
      done
      rm \$(basename ${vcf} .gz)      
      """
}