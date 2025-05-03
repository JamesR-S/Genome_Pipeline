#!/usr/bin/env nextflow
process HOMOZYGOSITY {
    tag "${family}"
    module 'BCFtools/1.17-GCC-12.2.0'
    publishDir "${params.batchDir}/r04_metrics", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(vcf), file(csi)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("*_homozygosity.csv")
    script:
      """
      tabix -p vcf ${vcf}
      ids=( ${id.join(" ")} )
      for i in \${ids[@]}; do
           java -Xmx9g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -cp ${params.javaDir}:${params.gatkJar} VcfToHomozygosity7 ${vcf} \$i > \${i}_homozygosity.csv
      done    
      """
}

process SHARED_HAPLOTYPES {
    tag "${family}"
    module 'BCFtools/1.17-GCC-12.2.0'
    publishDir "${params.batchDir}/r04_metrics", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(vcf), file(csi)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("*_homozygosity.csv")
    script:
      """
      tabix -p vcf ${vcf}
      ids=( ${id.join(" ")} )
      for (( i=0;            i < \${#ids[@]}; i++ )); do       
        for (( j=i+1;      j < \${#ids[@]}; j++ )); do  
           java -Xmx9g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 -cp ${params.javaDir}:${params.gatkJar} VcfToHomozygosity7 ${vcf} -p \${ids[i]} \${ids[j]} > \${ids[i]}-\${ids[j]}_homozygosity.csv
      done
      done    
      """
}

process UPD {
    tag "${family}"
    module 'BCFtools/1.17-GCC-12.2.0'
    publishDir "${params.batchDir}/r04_metrics", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(vcf), file(csi)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("*_UPD.csv")
    script:
      """
      tabix -p vcf ${vcf}
      ids=( ${id.join(" ")} )

      for (( i=0; i < \${#ids[@]}; i++ )); do
        for (( j=0; j < \${#ids[@]}; j++ )); do
          [[ \$i -eq \$j ]] && continue    # skip identical-sample case

          java -Xmx9g -XX:ParallelGCThreads=4 -XX:ConcGCThreads=4 \
              -cp ${params.javaDir}:${params.gatkJar} VcfToUPD2 \
              ${vcf} "\${ids[\${i}]}" "\${ids[\${j}]}" \
              > "\${ids[\${i}]}-\${ids[\${j}]}_UPD.csv"
        done
      done
      """
}