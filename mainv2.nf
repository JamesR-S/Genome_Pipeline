#!/usr/bin/env nextflow
nextflow.enable.dsl=2

params.batchDir = params.batchDir ?: '.'
params.control  = params.control  ?: "${params.batchDir}/control"

include { CONTROL_PARSER } from './modules/parse_control.nf'
include { CONTAM_SMALL } from './modules/clean_call_contamination.nf'
include { EXPANSION_HUNTER_DE_NOVO } from './modules/expansionHunterDeNovo.nf'
include { MOBILE_ELEMENTS } from './subworkflows/xtea_ME.nf'
include { TRIO_DE_NOVO } from './subworkflows/trio_de_novo.nf'
include { FASTQ_TO_BAM } from './subworkflows/fastqtobam.nf'
include { COVERAGE } from './subworkflows/coverage.nf'
include { SNV_INDEL_CALLING } from './subworkflows/snv_indel_calling.nf'
include { HOMOZYGOSITY_AND_HAPLOTYPES } from './subworkflows/homozygosity_and_haplotypes.nf'
include { QC } from './subworkflows/qc.nf'
include { CNV_CALLING } from './subworkflows/cnv_calling.nf'
include { ANNOTATION } from './subworkflows/annotation.nf'
include { CYTOMEGALOVIRUS } from './subworkflows/cytomegalovirus.nf'
include { BATCH_RELATEDNESS } from './subworkflows/batch_relatedness.nf'
include {CRAM2BAM} from './modules/cram_to_bam.nf'
include {SPRING2FQ} from './modules/spring_to_fastq.nf'
include {DUPMETRICS} from './modules/duplicates_metrics.nf'
include { buildStatusById; parseLineToMeta; parseLineToTuple; parseLineToTupleSpring; makeParsedLines } from './lib/helpers.nf'

workflow {

      spring_dir = file(params.batchDir + "/spring")

      ch_ref_fasta = file(params.referenceFasta)
      ch_ref_fai = file(params.referenceFasta + ".fai")
      ch_ref_gff = file( params.referenceGFF )
      ch_gnomad_common = file ( params.gnomadCommon )
      ch_gnomad_common_idx = file ( params.gnomadCommon + ".csi" )

      def ch_control = file(params.control)
      def controlFile = new File(ch_control.toString())
      def controlLines = makeParsedLines(controlFile)

      def metaById = [:]
      controlLines.each { line ->
        def m = parseLineToMeta(line)
        if( !metaById.containsKey(m.id as String) )
            metaById[m.id as String] = m
      }

      def rowsForStatus = controlLines.collect { line ->
        def m = parseLineToMeta(line)
        [ m.id, null, null, m.family, m.trio ]
      }
      def statusById = buildStatusById(rowsForStatus)

      // ---- DEBUG: print per-sample flags ----
      println "\n=== STATUS FLAGS (per sample) ==="
      metaById.keySet().sort().each { id ->
          def s = statusById[id]
          println sprintf(
              "%-20s cram_needed=%-5s qc_needed=%-5s bam_needed=%-5s snv_needed=%-5s cov_needed=%-5s cnv_needed=%-5s",
              id,
              s.cram_needed, s.qc_needed, s.bam_needed,
              s.snv_needed, s.cov_needed, s.cnv_needed
          )
      }
      println "=== END STATUS FLAGS ===\n"


      def ch_cram_existing = Channel
        .from(metaById.keySet().toList())
        .filter { id -> !statusById[id].cram_needed }                 // has cram+crai
        .map { id ->
            def meta = metaById[id]
            tuple(meta.id,meta.sex,meta.family,meta.trio,meta.famSampleCount, statusById[id].cram, statusById[id].crai)
        }

      def needFQIds = metaById.keySet().findAll { id -> statusById[id].cram_needed || statusById[id].qc_needed} as Set

      if (spring_dir.isDirectory() && !params.forcefq) {
        def springRows = controlLines
            .collect { parseLineToTupleSpring(it) }   // [ id, platform, sex, family, trio, flowcell, laneCount, famSampleCount, spring ]
            .findAll { row -> needFQIds.contains(row[0] as String) }

            Channel.from(springRows).set { ch_spring_need }

            SPRING2FQ (ch_spring_need)
            SPRING2FQ.out.set { ch_fq }

      } else {
            Channel.from(controlLines)
            .map { parseLineToTuple(it) }
            .filter { row -> needFQIds.contains(row[0] as String) }
            .set { ch_fq }
      }

      def ch_fq_existing = Channel
        .from(metaById.keySet().toList())
        .filter { id -> !statusById[id].qc_needed }                 
        .map { id ->
            def meta = metaById[id]
            tuple(meta.id,meta.sex,meta.family,meta.famSampleCount, statusById[id].fq_qc)
        }

      ch_fq
        .filter { row -> row[0] in statusById.keySet() && statusById[row[0]].qc_needed }
        .set { ch_qc_fq }


      QC(ch_qc_fq)
      QC.out.set { ch_check_fastq }
      
      def ch_final_fq_qc = ch_fq_existing.mix(ch_check_fastq)

      ch_fq
        .filter { row -> row[0] in statusById.keySet() && statusById[row[0]].cram_needed }
        .set { ch_cram_fq }

      FASTQ_TO_BAM (ch_cram_fq)
      FASTQ_TO_BAM.out.set { ch_cram_new }
      
      def ch_final_cram = ch_cram_existing.mix(ch_cram_new)

      ch_final_cram
        .filter { row -> row[0] in statusById.keySet() && statusById[row[0]].bam_needed }
        .set { ch_cram_to_bam }  

      CRAM2BAM (ch_cram_to_bam)
      CRAM2BAM.out.set { ch_final_bam }
      
      ch_final_bam
        .filter { row -> row[0] in statusById.keySet() && statusById[row[0]].dup_metrics_needed }
        .set { ch_dup_metrics }

      DUPMETRICS (ch_dup_metrics)

      CNV_CALLING (ch_final_bam, ch_ref_fasta,ch_ref_fai,statusById)

      ch_final_bam
        .filter { row -> row[0] in statusById.keySet() && statusById[row[0]].cymegv_needed }
        .set { ch_cymegv_bam }

      ch_final_fq_qc
        .filter { row -> row[0] in statusById.keySet() && statusById[row[0]].cymegv_needed }
        .set { ch_cymegv_fq_qc }    

      CYTOMEGALOVIRUS (ch_cymegv_bam, ch_cymegv_fq_qc)

      ch_final_bam
        .filter { row -> row[0] in statusById.keySet() && statusById[row[0]].te_needed }
        .set { ch_te_bam }        

      MOBILE_ELEMENTS (ch_te_bam, ch_ref_fasta, ch_ref_fai, ch_ref_gff)

      ch_final_bam
        .filter { row -> row[0] in statusById.keySet() && statusById[row[0]].exphunter_needed }
        .set { ch_exphunter_bam } 

      EXPANSION_HUNTER_DE_NOVO (ch_exphunter_bam)

      ch_final_bam
        .filter { row -> row[0] in statusById.keySet() && statusById[row[0]].contam_needed }
        .set { ch_contam_bam } 

      CONTAM_SMALL (ch_contam_bam)

      ch_final_bam
        .filter { row -> row[0] in statusById.keySet() && statusById[row[0]].cov_needed }
        .set { ch_cov_bam }       

      COVERAGE (ch_cov_bam,ch_control)

      ch_final_bam
        .filter { row -> row[0] in statusById.keySet() && statusById[row[0]].snv_needed }
        .set { ch_snv_bam }       

      SNV_INDEL_CALLING(ch_snv_bam, ch_ref_fasta, ch_ref_fai,statusById,metaById)
      SNV_INDEL_CALLING.out.single_sample.filter { row -> row[3] < 2 }
        .map { row -> tuple( [row[0]], row[1], row[2], row[3], row[4], row[5] )}
        .set { ch_singleton_vcf }

      SNV_INDEL_CALLING.out.family.mix(ch_singleton_vcf)
        .set { ch_combined_new_vcf }

      def families = metaById.values()
        .collect { it.family as String }
        .unique()

      def ch_vcf_existing = Channel
        .from(families)
        .filter { fam ->
            def rep = fam.tokenize('-')[0]
            !statusById[rep].fam_vcf_needed
        }
        .map { fam ->
            def ids = fam.tokenize('-')
            def rep = ids[0]
            def sexList = ids.collect { sid -> metaById[sid]?.sex }

            tuple(
                ids,                             
                sexList,                         
                fam,
                ids.size(),                   
                statusById[rep].fam_vcf,
                statusById[rep].fam_vcf_csi
            )
      }
 
      def ch_combined_vcf = ch_vcf_existing.mix(ch_combined_new_vcf)

      SNV_INDEL_CALLING.out.single_sample
        .set { ch_single_sample_vcf }

      BATCH_RELATEDNESS (ch_combined_vcf)      

      HOMOZYGOSITY_AND_HAPLOTYPES(ch_combined_vcf,statusById)

      ch_combined_vcf
      .filter { ids, sexList, fam, n, vcf, csi ->
        def rep = (ids instanceof List ? ids[0] : ids)
        statusById[rep].vep_needed
      }
      .set { ch_vep_vcf }
 

      ANNOTATION(ch_vep_vcf)

      TRIO_DE_NOVO (ch_final_bam, ch_single_sample_vcf, ch_ref_fasta, ch_ref_fai,ch_gnomad_common,ch_gnomad_common_idx,statusById)
}


workflow.onComplete { wf ->
    if (params.send_mail) {
        def email = "${System.getenv('USER') ?: 'unknown'}@exeter.ac.uk"
        def msg = """\
Workflow COMPLETED
Project : ${workflow.projectDir}
Run name: ${workflow.runName}
Time    : ${new Date()}
""".stripIndent()

        Mailer.send(email, "Nextflow workflow COMPLETED: ${workflow.runName}", msg)

     //   ["bash", "-c", "find ${params.batchDir}/r04* -type d -exec chmod 2775 {} +"].execute().waitFor()
     //   ["bash", "-c", "find ${params.batchDir}/r04* -type f -exec chmod 664 {} +"].execute().waitFor()
    }
}
