include { DEEP_TRIO } from '../modules/deep_trio.nf'
include { DEEP_TRIO_DENOVO } from '../modules/deep_trio.nf'
workflow TRIO_DE_NOVO {
    take:
    ch_final_bam
    ch_ref_fasta
    ch_ref_fai

    main:
    ch_final_bam
        .filter { row -> row[3] != 'NA' }
        .map { row ->
                def (id, sex, family, trio, famSampleCount, bam_file ,bai_file) = row
                def key = [family:family, trio:trio, famSampleCount:famSampleCount]        
                tuple(key, [id:id,sex:sex, bam:bam_file, bai:bai_file])
            }
        .groupTuple(size: 3)
        .map { key, bam_bai -> 
                def meta = key
                def orderedIds = meta.trio.tokenize('-')
                def idToIndex = orderedIds.collectEntries { famId ->
                [(famId): orderedIds.indexOf(famId)]
                }
                def sortedGroup = bam_bai.sort { rec ->
                idToIndex[rec.id]
                }
                def sortedIds  = sortedGroup*.id
                def sortedSex      = sortedGroup*.sex         
                def sortedbams = sortedGroup*.bam
                def sortedbais = sortedGroup*.bai
                tuple(sortedIds, sortedSex,meta.trio.tokenize('-'), sortedbams, sortedbais)
                }  
        .set { ch_trios_bam }


    DEEP_TRIO (ch_trios_bam, ch_ref_fasta, ch_ref_fai)
        .set{ ch_deep_trios }

    DEEP_TRIO_DENOVO (ch_deep_trios)
    }