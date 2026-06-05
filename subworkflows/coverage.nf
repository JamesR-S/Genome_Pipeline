include { DEPTH_OF_COVERAGE } from '../modules/depth_of_coverage.nf'
include { INDEX_COVERAGE } from '../modules/index_coverage.nf'
include { COVERAGE_REPORT } from '../modules/coverage_report.nf'
include { COVERAGE_BINNER } from '../modules/coverage_binner.nf'
include { XY_COVERAGE } from '../modules/xy_coverage.nf'
include { INSERT_SIZES } from '../modules/insert_sizes.nf'
include { CLIP_RATE } from '../modules/clip_rate.nf'

workflow COVERAGE {
    take:
    ch_final_bam
    ch_control

    main:
    def needsCovBinner = { id -> !file("${params.batchDir}/r04_metrics/${id}.coverageBinner").exists() || params.rerun_all }
    def needsInsertSizes = { id -> !file("${params.batchDir}/r04_metrics/${id}.insertSize.stats").exists() || !file("${params.batchDir}/r04_metrics/${id}.insertSize.histogram").exists() || params.rerun_all }
    def needsClipRate = { id -> !file("${params.batchDir}/r04_metrics/${id}.clipRate").exists() || params.rerun_all }

    ch_final_bam
        .collect(flat: false)
        .map { rows ->
        rows.sort { it[0] }              
        tuple( rows.collect{ it[0] },   
               rows.collect{ it[1] },   
               rows.collect{ it[2] },   
               rows.collect{ it[3] },   
               rows.collect{ it[4] },   
               rows.collect{ it[5] },   
               rows.collect{ it[6] } )  
    }
    .set { ch_collapsed } 
    
    def ch_cov_binner_needed = ch_final_bam
        .filter { row -> needsCovBinner(row[0] as String) }

    def ch_cov_binner_existing = ch_final_bam
        .filter { row -> !needsCovBinner(row[0] as String) }
        .map { row ->
            def (id, sex, family, trio, famSampleCount, bam, bai) = row
            tuple(id, sex, file("${params.batchDir}/r04_metrics/${id}.coverageBinner"))
        }

    COVERAGE_BINNER(ch_cov_binner_needed)
    def ch_cov_binner_all = ch_cov_binner_existing.mix(COVERAGE_BINNER.out)

    ch_cov_binner_all
        .collect(flat: false)
        .map { rows ->
            rows.sort { it[0] }
            tuple( rows.collect{ it[0] },
                   rows.collect{ it[1] },
                   rows.collect{ it[2] } )
        }
        .set { ch_cb_collapsed }

    INSERT_SIZES(ch_final_bam.filter { row -> needsInsertSizes(row[0] as String) })

    CLIP_RATE(ch_final_bam.filter { row -> needsClipRate(row[0] as String) })

    if( !file("${params.batchDir}/r04_metrics/Coverage.indexed").exists() || params.rerun_all) {
        DEPTH_OF_COVERAGE(ch_collapsed)
            .set { ch_coverage }

        INDEX_COVERAGE(ch_coverage,ch_control)
            .set { ch_index_coverage }
    }else {
        ch_index_coverage = Channel.fromPath("${params.batchDir}/r04_metrics/Coverage.indexed")
    }

    if( !file("${params.batchDir}/r04_metrics/coverage_report").exists() || params.rerun_all) {    
        COVERAGE_REPORT(ch_index_coverage)
    }

    if( !file("${params.batchDir}/r04_metrics/XY_coverage").exists() || params.rerun_all) {
        XY_COVERAGE(ch_cb_collapsed)
    }
}
