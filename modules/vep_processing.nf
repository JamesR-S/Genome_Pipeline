process VEP_PROCESSING {
    tag "${family}"
    module 'BCFtools/1.17-GCC-12.2.0'
    publishDir "r04_vep", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(vcf)
    output:
      tuple val(id), val(sex), val(family), val(famSampleCount), file("${family}_vep_annotated.vcf.gz"), file("${family}_vep_annotated.vcf.gz.csi"), file("${family}_vep_annotated.tsv")
    script:
      """
      bcftools view -Oz -o ${family}_vep_annotated.vcf.gz ${vcf}
      bcftools index ${family}_vep_annotated.vcf.gz

      bcftools +split-vep -HH -d -f '%CHROM\t%POS\t%ID\t%REF\t%ALT[\t%GT][\t%GQ][\t%DP][\t%AD][\t%PL]\t%CSQ\n' -o  ${family}_vep_annotated.tsv -A tab ${family}_vep_annotated.vcf.gz

      """
}