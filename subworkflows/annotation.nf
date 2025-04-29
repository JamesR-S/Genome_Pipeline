#!/usr/bin/env nextflow
include { VCF_FILTER } from '../modules/vcf_filter.nf'
include { VEP } from '../modules/vep.nf'
include { VEP_PROCESSING } from '../modules/vep_processing.nf'

workflow ANNOTATION {
    take:
    ch_mixed_vcf

    main:

    VCF_FILTER(ch_mixed_vcf)
     .set { ch_filtered_vcf }

    VEP(ch_filtered_vcf)
     .set { ch_anno_vcf }

    VEP_PROCESSING(ch_anno_vcf)



}