include { MANTA } from '../modules/manta.nf'
include { SURVINDEL2 } from '../modules/survindel2.nf'
include { PARLIAMENT2 } from '../modules/parliament2.nf'
workflow CNV_CALLING {
    take:
    ch_final_bam
    ch_ref_fasta
    ch_ref_fai

    main:

    manta_bed = file("${params.mantaChromBed}")
    manta_bed_idx = file("${params.mantaChromBed}.tbi")
    ch_final_bam
    .map {row ->
            def (id, sex, family, trio, famSampleCount, bam, bai) = row
            def key = [family:family, famSampleCount:famSampleCount]
            def gKey = groupKey(key, famSampleCount)          
            tuple(gKey, [id:id,sex:sex, bam:bam, bai:bai])
        }
    .groupTuple() 
    .map { key, bams -> 
            def meta = key.getGroupTarget()
            def orderedIds = meta.family.tokenize('-')
            def idToIndex = orderedIds.collectEntries { famId ->
            [(famId): orderedIds.indexOf(famId)]
            }
            def sortedGroup = bams.sort { rec ->
            idToIndex[rec.id]
            }
            def sortedIds      = sortedGroup*.id
            def sortedSex      = sortedGroup*.sex        
            def sortedBams    = sortedGroup*.bam
            def sortedBais = sortedGroup*.bai
            tuple(sortedIds, sortedSex,meta.family,meta.famSampleCount, sortedBams, sortedBais)
            }
    .set  { family_bams }

    MANTA (family_bams, ch_ref_fasta,ch_ref_fai,manta_bed,manta_bed_idx)
        .set { ch_manta_vcf }

    SURVINDEL2 (ch_final_bam, ch_ref_fasta,ch_ref_fai)

    PARLIAMENT2 (ch_final_bam, ch_ref_fasta,ch_ref_fai)
        .set { ch_parliament_vcf }

    }