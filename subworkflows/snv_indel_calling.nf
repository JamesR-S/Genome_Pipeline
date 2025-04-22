include { DEEP_VARIANT } from '../modules/deep_variant.nf'
include { GLNEXUS } from '../modules/glnexus.nf'
workflow SNV_INDEL_CALLING {
    take:
    ch_final_bam
    ch_ref_fasta
    ch_ref_fai

    main:

    DEEP_VARIANT (ch_final_bam, ch_ref_fasta, ch_ref_fai)

    DEEP_VARIANT.out.vcf.set { ch_vcf }
    DEEP_VARIANT.out.gvcf
        .filter { row -> row[4] >= 2 }
        .map {row ->
                def (id, sex, family, famSampleCount, gvcf, gvcfcsi) = row
                def key = [family:family, famSampleCount:famSampleCount]
                def gKey = groupKey(key, famSampleCount)          
                tuple(gKey, [id:id,sex:sex, gvcf:gvcf, gvcfcsi:gvcfcsi])
            }
        .groupTuple() 
        .map { key, gvcfs -> 
                def meta = key.getGroupTarget()
                def orderedIds = meta.family.tokenize('-')
                def idToIndex = orderedIds.collectEntries { famId ->
                [(famId): orderedIds.indexOf(famId)]
                }
                def sortedGroup = gvcfs.sort { rec ->
                idToIndex[rec.id]
                }
                def sortedIds      = sortedGroup*.id
                def sortedSex      = sortedGroup*.sex        
                def sortedGvcfs    = sortedGroup*.gvcf
                def sortedGvcfCsis = sortedGroup*.gvcfcsi
                tuple(sortedIds, sortedSex,meta.family,meta.famSampleCount, sortedGvcfs, sortedGvcfCsis)
                }
        .set  { family_gvcf }

    GLNEXUS (family_gvcf)
    emit:
    ch_vcf
}