include { PARABRICKS_FQ2BAM } from '../modules/parabricks_fq2bam.nf'
include { RMDUP } from '../modules/remove_duplicates.nf'
workflow FASTQ_TO_BAM_PARABRICKS {
    take:
    ch_parsed

    main:

    ch_parsed
        .map { row ->
            def (id, platform, sex, family, trio, flowcell, laneCount, famSampleCount, fastq1, fastq2) = row
            def key = [id:id, platform:platform, sex:sex, family:family, trio:trio, famSampleCount:famSampleCount]
            def fastqFiles = [flowcell:flowcell, f1:fastq1, f2:fastq2]
            def gKey = groupKey(key, laneCount)          
            tuple(gKey, fastqFiles)
        }
        .groupTuple() 
        .map { key, fastqFiles -> tuple(key.getGroupTarget(), fastqFiles.flowcell, fastqFiles.f1, fastqFiles.f2) }
        .set  { ch_grouped_fq }

    PARABRICKS_FQ2BAM (ch_grouped_fq)
        .set { ch_md_bam }

    RMDUP (ch_md_bam)
        .set { ch_final_bam }
    emit:
    ch_final_bam
}