process XTEA {
    tag "${family}"
    container 'jamesrusssilsby/exetea:0.1.9d'
    containerOptions " -B ${params.xtea_libraries}"
    cpus 16
    publishDir(
        path: { "r04_transposable_elements" },
        pattern: "*.vcf*",
        mode: 'copy')
    
    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(bam), file(bai)
      file(Fasta)
      file(Fai)
      file(GFF)
    output:

      tuple val(id), val(sex), val(family), val(famSampleCount), file("*.vcf"), emit: vcf
    script:
      """

      declare -a ids=( ${id.join(" ")} )

      for i in "\${ids[@]}"
      do
        echo -e "\${i}" >> ${family}_samples.tsv
        echo -e "\${i}\\t\${i}.bam" >> ${family}_bams.tsv
      done

      cat ${family}_bams.tsv
      cat ${family}_samples.tsv

       ${params.xtea_libraries}xtea \
       -i ${family}_samples.tsv \
       -b ${family}_bams.tsv \
       -x null \
       -p \$PWD \
       -o jobs.sh \
       -l ${params.xtea_libraries}rep_lib_annotation/ \
       -r ${Fasta[0]} \
       -g ${GFF} \
       --xtea /data/xTea/xtea/ \
       -f 5907 \
       -y 7

      sed -n 's/^sbatch[[:space:]]*<[[:space:]]*\\(.*\\)\$/\\1/p' jobs.sh \
      | parallel -j16 'bash < {}'

      for file in WG*/*/*.vcf
      do
        grep -v "orphan" \$file > \$(basename \$file))
      done
      """
}