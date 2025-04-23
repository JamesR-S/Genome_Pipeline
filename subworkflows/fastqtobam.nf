include { BWA_MEM } from '../modules/bwa_mem.nf'
include { KEVLAR_COUNT } from '../modules/kevlar_count.nf'
include { SUM_READ_COUNTS } from '../modules/sum_read_counts.nf'
include { MERGE_SAMS } from '../modules/merge_sam.nf'
include { FIXMATE } from '../modules/fix_mate.nf'
include { MARKDUP } from '../modules/mark_duplicates.nf'
workflow FASTQ_TO_BAM {
    take:
    ch_parsed

    main:
    BWA_MEM (ch_parsed)
        .map { row ->
            def (id, sex, family, trio, laneCount, famSampleCount, sam_file) = row
            def key = [id:id, sex:sex, family:family, trio:trio, famSampleCount:famSampleCount]
            def gKey = groupKey(key, laneCount)          
            tuple(gKey, sam_file)
        }
        .groupTuple() 
        .map { key, sam_file -> tuple(key.getGroupTarget(), sam_file) }
        .set  { ch_raw_sams }

    KEVLAR_COUNT (ch_parsed)
        .map { row ->
            def (id, sex, family, trio, laneCount, famSampleCount, ct_file) = row
            def key = [id:id, sex:sex, family:family, trio:trio, famSampleCount:famSampleCount]
            def gKey = groupKey(key, laneCount)          
            tuple(gKey, ct_file)
        }
        .groupTuple() 
        .map { key, ct_file -> tuple(key.getGroupTarget(), ct_file) }
        .set  { ch_grouped_ct }

    SUM_READ_COUNTS (ch_grouped_ct)

    MERGE_SAMS (ch_raw_sams)
        .set  { ch_mi_bams }

    FIXMATE (ch_mi_bams)
        .set  { ch_fixmate }
  
    MARKDUP (ch_fixmate)
        .set  { ch_final_bam }

    emit:
    ch_final_bam
}