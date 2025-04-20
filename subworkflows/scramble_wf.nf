include { SCRAMBLE_CLUST_IDENT } from '../modules/scramble.nf'
include { SPLIT_CLUST_FILE } from '../modules/scramble.nf'
include { SCRAMBLE_CLUST_ANALYSIS } from '../modules/scramble.nf'
include { CAT_CLUST_FILE } from '../modules/scramble.nf'
workflow SCRAMBLE_WF {
    take:
    bam_files

    main:
    SCRAMBLE_CLUST_IDENT (bam_files)
         .set  { ch_scramble_ident }

    SPLIT_CLUST_FILE (ch_scramble_ident)
         .flatMap { sampleName, chunkFiles ->
           chunkFiles.sort().indexed().collect { idx, chunkFile ->
            [ sampleName, idx, chunkFile ]
            }
         }
         .set { ch_split_chunks }

    SCRAMBLE_CLUST_ANALYSIS (ch_split_chunks)
    .groupTuple(size: 5)
    .map { sampleName, chunkList ->
        def sorted = chunkList.sort { it[0] } 
        def chunkFiles = sorted.collect { it[1] } 
        [ sampleName, chunkFiles ]
    }
    .set { ch_grouped_chunks }

    CAT_CLUST_FILE (ch_grouped_chunks)
}