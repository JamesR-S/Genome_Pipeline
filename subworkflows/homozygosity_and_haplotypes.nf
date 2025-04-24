include { HOMOZYGOSITY } from '../modules/savvy.nf'
include { SHARED_HAPLOTYPES } from '../modules/savvy.nf'
workflow HOMOZYGOSITY_AND_HAPLOTYPES {
    take:
    ch_mixed_vcf

    main:

   HOMOZYGOSITY(ch_mixed_vcf)

   ch_mixed_vcf
       .filter { row -> row[3] > 1 }
       .set { ch_multisample_vcf }

   SHARED_HAPLOTYPES(ch_multisample_vcf)
}