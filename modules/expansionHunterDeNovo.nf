process EXPANSION_HUNTER_DE_NOVO {
    tag "${id}"
    publishDir "r04_expansionhunterdenovo", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(bam), file(bai)
    output:
      tuple file("${id}.locus.tsv"), file("${id}.motif.tsv"), file("${id}.str_profile.json")
    script:
      """
      echo "Running expansionHunterDeNovo for sample ${id}"
      ${params.expHunterDeNovo} profile --reads ${bam} --reference ${params.referenceFasta} --output-prefix ${id} --min-anchor-mapq 50 --max-irr-mapq 40 
      """
}