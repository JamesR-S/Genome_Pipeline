include { BATCH_HOMOZYGOSITY } from '../modules/savvy.nf'
include { RELATEDNESS } from '../modules/vcftools_relatedness.nf'

workflow BATCH_RELATEDNESS {
    take:
    ch_mixed_vcf

    main:
    ch_mixed_vcf
        .collect(flat: false)
        .map { rows ->
        rows.sort { it[0] }              
        tuple( rows.collect{ it[0] },   
               rows.collect{ it[1] },   
               rows.collect{ it[2] },   
               rows.collect{ it[3] },   
               rows.collect{ it[4] },   
               rows.collect{ it[5] })  
    }
    .set { ch_vcf_collapsed } 

    if( !file("${params.batchDir}/r04_metrics/relatedness2.csv").exists() ) {
        RELATEDNESS(ch_vcf_collapsed)
    }
    if( !file("${params.batchDir}/r04_metrics/homozygosity.csv").exists() ) {
        BATCH_HOMOZYGOSITY(ch_vcf_collapsed)
    }
}