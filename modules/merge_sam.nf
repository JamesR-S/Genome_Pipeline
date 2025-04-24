#!/usr/bin/env nextflow
process MERGE_SAMS {
    tag "${meta.id}"
    module 'SAMtools/1.16.1-GCC-11.2.0'
    publishDir "r04_assembly", mode: 'copy'
    input:
      tuple val(meta), file(sams)
    output:
      tuple val(meta.id), val(meta.sex), val(meta.family), val(meta.trio), val(meta.famSampleCount), file("${meta.id}_sorted.bam"), file("${meta.id}_sorted.bai")
    script:
    """
    echo "Merging SAM files for sample ${meta.id}"
    # Count number of SAM files. Nextflow passes the list in a way that bash can see multiple paths.
    sam_files=( ${sams.join(" ")} )
    num_files=\$(echo \${sam_files[@]} | wc -w)
    if [ \$num_files -gt 1 ]; then
       inputs=""
       for f in \${sam_files[@]}; do
           inputs="\${inputs} I=\$f"
       done
       java -jar ${params.picardJar} MergeSamFiles \${inputs} \
          O=${meta.id}_tmp.sam SO=coordinate TMP_DIR=${params.tmpDir}
       samtools sort -@ 16 ${meta.id}_tmp.sam > ${meta.id}_sorted.bam
       samtools index -@ 16 ${meta.id}_sorted.bam > ${meta.id}_sorted.bai
    else
         # If only one file is present, simply copy it to the output name.
        samtools sort -@ 16 ${sams} > ${meta.id}_sorted.bam
         samtools index -@ 16 ${meta.id}_sorted.bam > ${meta.id}_sorted.bai
    fi
    """
}
