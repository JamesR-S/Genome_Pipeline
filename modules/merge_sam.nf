#!/usr/bin/env nextflow
process MERGE_SAMS {
    module = 'SAMtools/1.17-GCC-12.2.0'
    tag "${sampleName}"
    publishDir "r03_assembly", mode: 'copy'
    input:
      // Expect a tuple: sampleName and a list of SAM files
      tuple val(id), val(sex), val(family), val(trio), val(laneCount), val(famSampleCount), file(sams)
    output:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file("${id}.sam"), file("${id}.sai")
    script:
    """
    echo "Merging SAM files for sample ${sampleName}"
    # Count number of SAM files. Nextflow passes the list in a way that bash can see multiple paths.
    sam_files=( ${sams.join(" ")} )
    num_files=\$(echo \${sam_files[@]} | wc -w)
    if [ \$num_files -gt 1 ]; then
       inputs=""
       for f in \${sam_files[@]; do
           inputs="\${inputs} I=\$f"
       done
       java -jar ${params.picardJar} MergeSamFiles \${inputs} \
          O=${id}.sam SO=coordinate CREATE_INDEX=true TMP_DIR=${params.tmpDir}
    else
         # If only one file is present, simply copy it to the output name.
         cp ${sams} ${id}.sam
         samtools index ${id}.sam
      fi
      """
}
