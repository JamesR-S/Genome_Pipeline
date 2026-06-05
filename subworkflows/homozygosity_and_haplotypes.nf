include { HOMOZYGOSITY } from '../modules/savvy.nf'
include { SHARED_HAPLOTYPES } from '../modules/savvy.nf'
include { UPD } from '../modules/savvy.nf'
workflow HOMOZYGOSITY_AND_HAPLOTYPES {
    take:
    ch_mixed_vcf
    statusById

    main:

    ch_mixed_vcf
    .filter { ids, sex, family, n, vcf, vcfcsi ->
        def rep = (ids instanceof List ? ids[0] : ids)
        statusById[rep].sample_homoz_needed
    }
    .set { ch_HZ_vcf}  

   HOMOZYGOSITY(ch_HZ_vcf)

   ch_mixed_vcf
       .filter { row -> row[3] > 1 }
       .set { ch_multisample_vcf }

    ch_multisample_vcf
    .filter { ids, sex, family, n, vcf, vcfcsi ->
        def rep = (ids instanceof List ? ids[0] : ids)
        statusById[rep].shared_haps_needed
    }
    .set { ch_haps_vcf}  

   SHARED_HAPLOTYPES(ch_haps_vcf)

    ch_multisample_vcf
    .filter { ids, sex, family, n, vcf, vcfcsi ->
        def rep = (ids instanceof List ? ids[0] : ids)
        statusById[rep].upd_needed
    }
    .set { ch_UPD_vcf}  

   UPD(ch_UPD_vcf)
}