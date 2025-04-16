process SCRAMBLE_CLUST_IDENT {
    tag "${id}"
    publishDir "r03_scramble", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(trio), val(famSampleCount), file(bam), file(bai)
    output:
      tuple val(id), file("clusters_${id}.txt")
    script: 
      """
      ${params.scrambleLocation}cluster_identifier ${bam} > clusters_${id}.txt
      """
}

process SPLIT_CLUST_FILE {
    tag "${id}"
    input:
      tuple val(id), file(ClusterFile)

    output:
      tuple val(id), file("*.split_*")
    script:
    """
    split -dn l/5 ${ClusterFile} ${id}.split_
    """
}

process SCRAMBLE_CLUST_ANALYSIS {
    tag "${id}_${idx}"
    input:
      tuple val(id), val(idx), file(partial_clusters)
    output:
      tuple val(id), val(idx), file("analysis_${id}_partial.txt0${idx}")
    script:
      """
      echo "Running expansionHunterDeNovo for sample ${id}"
      ${params.scrambleLocation}cluster_analysis --out-name analysis_${id}_partial.txt0${idx} --cluster-file ${partial_clusters} --install-dir ${params.scrambleLocation}scramble-master/cluster_analysis/bin --mei-refs {params.scrambleLocation}scramble-master/cluster_analysis/resources/MEI_consensus_seqs.fa
      """
}

process CAT_CLUST_FILE {
    tag "${id}"
    publishDir "r03_scramble", mode: 'copy'
    input:
      tuple val(id), file(chunkFiles)
    output:
      file("analysis_${id}.txt")
    script:
    """
    cat ${chunkFiles.join(' ')} > analysis_${id}.txt
    """
}
