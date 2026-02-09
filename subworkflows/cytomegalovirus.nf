include { EXTRACT_UNMAPPED } from '../modules/extract_unmapped.nf'
include { CYTOMEGALOVIRUS_COUNT } from '../modules/cytomegalovirus_count.nf'
include { ALIGN_CYTOMEGALOVIRUS } from '../modules/align_cytomegalovirus.nf'

workflow CYTOMEGALOVIRUS {
    take:
    ch_final_bam
    ch_check_fastq

    main:

    EXTRACT_UNMAPPED(ch_final_bam)
        .set { ch_unmapped }

    ALIGN_CYTOMEGALOVIRUS(ch_unmapped)
        .join(ch_check_fastq)
        .map { row -> 
            def (id, sex_sam, family_sam, famCt_sam, sam, sex_cfq,  family_cfq, famCt_cfq, cfq) = row

           // sanity-checks (optional but useful)
           assert sex_sam == sex_cfq
           assert family_sam == family_cfq
           assert famCt_sam == famCt_cfq
      
            tuple(id, sam, cfq)
        }
        .collect(flat: false)
        .map { rows ->
        rows.sort { it[0] }              
        tuple( rows.collect{ it[0] },   
               rows.collect{ it[1] },   
               rows.collect{ it[2] })  
    }
    .set { ch_sam_cfq_collapsed } 

if( !file("${params.batchDir}/r04_cytomegalovirus/stats").exists() || params.rerun_all) {
    CYTOMEGALOVIRUS_COUNT(ch_sam_cfq_collapsed)
}

}