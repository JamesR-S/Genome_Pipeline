include { PARABRICKS_DV_VCF } from '../modules/parabricks_dv_vcf.nf'
include { PARABRICKS_DV_GVCF } from '../modules/parabricks_dv_gvcf.nf'
include { DV_VCF_PROCESSING } from '../modules/process_pdv.nf'
include { DV_GVCF_PROCESSING } from '../modules/process_pdv.nf'
include { GLNEXUS } from '../modules/glnexus.nf'
include { ANCESTRY } from '../modules/ancestry.nf'
workflow SNV_INDEL_CALLING_GPU {
    take:
    ch_final_bam
    ch_ref_fasta
    ch_ref_fai

    main:

    PARABRICKS_DV_VCF (ch_final_bam, ch_ref_fasta, ch_ref_fai)
        .set { ch_initial_vcf }

    DV_VCF_PROCESSING(ch_initial_vcf)
        .set { ch_vcf }

    PARABRICKS_DV_GVCF (ch_final_bam, ch_ref_fasta, ch_ref_fai)
        .set { ch_initial_gvcf }

    DV_GVCF_PROCESSING(ch_initial_gvcf)
        .set { ch_gvcf }

    ch_gvcf
        .filter { row -> row[3] >= 2 }
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
        .set  { ch_family_gvcf }

    GLNEXUS (ch_family_gvcf)
        .set { ch_family_vcf }

    ANCESTRY(ch_gvcf)

    emit:
    single_sample = ch_vcf
    family = ch_family_vcf
}