include { MANTA } from '../modules/manta.nf'
include { SURVINDEL2 } from '../modules/survindel2.nf'
include { PARLIAMENT2 } from '../modules/parliament2.nf'
include { buildStatusById; parseLineToMeta; parseLineToTuple; parseLineToTupleSpring } from '../lib/helpers.nf'

workflow CNV_CALLING {
    take:
    ch_final_bam
    ch_ref_fasta
    ch_ref_fai
    statusById

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

    family_bams
    .filter { ids, sex, family, n, bam, bai ->
        def rep = (ids instanceof List ? ids[0] : ids)
        statusById[rep].cnv_needed
    }
    .set { ch_manta_bam }    

    MANTA (ch_manta_bam, ch_ref_fasta,ch_ref_fai,manta_bed,manta_bed_idx)
        .set { ch_manta_vcf }

    ch_final_bam
        .filter { row -> row[0] in statusById.keySet() && statusById[row[0]].survindel_needed }
        .set { ch_survindel_bam }  


    SURVINDEL2 (ch_survindel_bam, ch_ref_fasta,ch_ref_fai)

    ch_final_bam
        .filter { row -> row[0] in statusById.keySet() && statusById[row[0]].parliament_needed }
        .set { ch_parliament_bam }  

    PARLIAMENT2 (ch_parliament_bam, ch_ref_fasta,ch_ref_fai)
        .set { ch_parliament_vcf }

    }