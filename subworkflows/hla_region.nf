include { CALL_HLA_VARIANTS } from '../modules/call_hla_variants.nf'
include { EXTRACT_HLA } from '../modules/extract_HLA.nf'
workflow  HLA_REGION {
    take:
    ch_final_bam

    main:

    EXTRACT_HLA(ch_final_bam)
    .set { ch_hla_bam }

    CALL_HLA_VARIANTS(ch_hla_bam)
}