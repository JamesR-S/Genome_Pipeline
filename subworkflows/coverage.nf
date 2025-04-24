include { DEPTH_OF_COVERAGE } from '../modules/depth_of_coverage.nf'
include { INDEX_COVERAGE } from '../modules/index_coverage.nf'
include { COVERAGE_REPORT } from '../modules/coverage_report.nf'
include { XY_COVERAGE } from '../modules/xy_coverage.nf'
workflow COVERAGE {
    take:
    ch_final_bam

    main:
    ch_final_bam
        .collect()
        .map { rows ->              
        tuple( rows.collect{ it[0] },   
               rows.collect{ it[1] },   
               rows.collect{ it[2] },   
               rows.collect{ it[3] },   
               rows.collect{ it[4] },   
               rows.collect{ it[5] },   
               rows.collect{ it[6] } )  
    }
    .set { ch_collapsed } 
    
    DEPTH_OF_COVERAGE(ch_collapsed)
        .set { ch_coverage }

    INDEX_COVERAGE(ch_coverage)
        .set { ch_index_coverage }

    COVERAGE_REPORT(ch_index_coverage)

    XY_COVERAGE(ch_coverage)
}