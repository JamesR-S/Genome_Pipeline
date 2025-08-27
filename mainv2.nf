#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { CONTROL_PARSER } from './modules/parse_control.nf'
include { CONTAM_SMALL } from './modules/clean_call_contamination.nf'
include { EXPANSION_HUNTER_DE_NOVO } from './modules/expansionHunterDeNovo.nf'
include { MOBILE_ELEMENTS } from './subworkflows/xtea_ME.nf'
include { TRIO_DE_NOVO } from './subworkflows/trio_de_novo.nf'
include { DEEP_TRIO_DE_NOVO } from './subworkflows/deep_trio_de_novo.nf'
include { FASTQ_TO_BAM } from './subworkflows/fastqtobam.nf'
include { FASTQ_TO_BAM_PARABRICKS } from './subworkflows/fastqtobam_parabricks.nf'
include { SNV_INDEL_CALLING_GPU } from './subworkflows/snv_indel_calling_gpu.nf'
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
// Helper function: parse one line of "key=value" pairs
def parseLineToTuple(String line) {
    def pairs = line.split(/;/)
    def map   = [:]
    pairs.each { kv ->
       def (k,v) = kv.split(/=/,2)
       map[k.trim()] = v.trim()
    }
    // Build the meta map
    def id = map.sample   // or 'sample'
    def platform = map.platform
    def sex = map.sex
    def family = map.family
    def trio = map.trio
    def flowcell = map.flowcell
    def laneCount = map.sampleLaneCount.toInteger()
    def famSampleCount = map.familySampleCount.toInteger()

    // Build the list of file() objects
    def fq1 = file(params.batchDir+"/fastq/"+map.fastq1)
    def fq2 = file(params.batchDir+"/fastq/"+map.fastq2)
    
    return [ id, platform, sex, family, trio, flowcell, laneCount, famSampleCount, fq1, fq2 ]
}

def parseLineToTupleSpring(String line) {
    def pairs = line.split(/;/)
    def map   = [:]
    pairs.each { kv ->
       def (k,v) = kv.split(/=/,2)
       map[k.trim()] = v.trim()
    }
    // Build the meta map
    def id = map.sample   // or 'sample'
    def platform = map.platform
    def sex = map.sex
    def family = map.family
    def trio = map.trio
    def flowcell = map.flowcell
    def laneCount = map.sampleLaneCount.toInteger()
    def famSampleCount = map.familySampleCount.toInteger()
    def fq1_name = new File(map.fastq1).name
    def fq2_name = new File(map.fastq2).name

    def (fq1_base, fq2_base) = [fq1_name, fq2_name].collect {
        it.replaceFirst(/(\.fastq\.gz|\.fq\.gz|\.fastq|\.fq)$/, '')
    }

    // find the longest common prefix
    int i = 0
    while (i < fq1_name.size() && i < fq2_name.size() && fq1_name[i] == fq2_name[i]) {
        i++
    }
    def common = fq1_name[0..<i].replaceFirst(/[_\.\-(_R)]+$/, '')  // trim trailing _.- if wanted

    def springName = "${common}.spring"
    def spring     = file("${params.batchDir}/spring/${springName}")
    
        return [ id, platform, sex, family, trio, flowcell, laneCount, famSampleCount, spring ]
    }

params.batchDir = file(params.batchDir ?: '.')
params.control = file(params.control ?: params.batchDir+"/control")

workflow {

      spring_dir = file(params.batchDir + "/spring")

      ch_control = file(params.control)
      ch_ref_fasta = file(params.referenceFasta)
      ch_ref_fai = file(params.referenceFasta + ".fai")
      ch_ref_gff = file( params.referenceGFF )
      ch_gnomad_common = file ( params.gnomadCommon )
      ch_gnomad_common_idx = file ( params.gnomadCommon + ".csi" )

      CONTROL_PARSER (ch_control)

      if (spring_dir.isDirectory()) {
            CONTROL_PARSER.out.reads
            .splitText()              
            .filter { it }            
            .map   { parseLineToTupleSpring(it) }
            .set  { ch_spring }

            SPRING2FQ (ch_spring)
            SPRING2FQ.out.set { ch_fq }

      } else {
            CONTROL_PARSER.out.reads
            .splitText()              
            .filter { it }            
            .map   { parseLineToTuple(it) }
            .set  { ch_fq }
      }

      QC(ch_fq)
      QC.out.set { ch_check_fastq }
      
      if (params.gpu) {
            FASTQ_TO_BAM_PARABRICKS (ch_fq)
            FASTQ_TO_BAM_PARABRICKS.out.set { ch_final_cram }
            }
      else {
            FASTQ_TO_BAM (ch_fq)
            FASTQ_TO_BAM.out.set { ch_final_cram }
      }
      
      CRAM2BAM (ch_final_cram)
      CRAM2BAM.out.set { ch_final_bam }

      DUPMETRICS (ch_final_bam)

      CNV_CALLING (ch_final_bam, ch_ref_fasta,ch_ref_fai)

      CYTOMEGALOVIRUS (ch_final_bam, ch_check_fastq)

      MOBILE_ELEMENTS (ch_final_bam, ch_ref_fasta, ch_ref_fai, ch_ref_gff)

      EXPANSION_HUNTER_DE_NOVO (ch_final_bam)
      
      CONTAM_SMALL (ch_final_bam)

      COVERAGE (ch_final_bam,ch_control)

      if (params.gpu) {
            SNV_INDEL_CALLING_GPU(ch_final_bam, ch_ref_fasta, ch_ref_fai)
            SNV_INDEL_CALLING_GPU.out.single_sample.filter { row -> row[3] < 2 }
                  .map { row -> tuple( [row[0]], row[1], row[2], row[3], row[4], row[5] )}
            .set { ch_singleton_vcf }

            SNV_INDEL_CALLING_GPU.out.family.mix(ch_singleton_vcf)
            .set { ch_combined_vcf }

            SNV_INDEL_CALLING_GPU.out.single_sample
                  .set { ch_single_sample_vcf }
      }
      else {
            SNV_INDEL_CALLING(ch_final_bam, ch_ref_fasta, ch_ref_fai)
            SNV_INDEL_CALLING.out.single_sample.filter { row -> row[3] < 2 }
                  .map { row -> tuple( [row[0]], row[1], row[2], row[3], row[4], row[5] )}
            .set { ch_singleton_vcf }

            SNV_INDEL_CALLING.out.family.mix(ch_singleton_vcf)
            .set { ch_combined_vcf }

            SNV_INDEL_CALLING.out.single_sample
                  .set { ch_single_sample_vcf }
      }

      BATCH_RELATEDNESS (ch_combined_vcf)      

      HOMOZYGOSITY_AND_HAPLOTYPES(ch_combined_vcf)

      ANNOTATION(ch_combined_vcf)

      if (params.denovocnn) {
      TRIO_DE_NOVO (ch_final_bam, ch_single_sample_vcf, ch_ref_fasta, ch_ref_fai,ch_gnomad_common,ch_gnomad_common_idx)
      }
      else {
      DEEP_TRIO_DE_NOVO (ch_final_bam, ch_ref_fasta, ch_ref_fai)
      }
}


workflow.onComplete { wf ->
    if (params.send_mail) {
        def email = params.email ?: "${System.getenv('USER') ?: 'unknown'}@exeter.ac.uk"
        def msg = """\
Workflow COMPLETED
Project : ${workflow.projectDir}
Run name: ${workflow.runName}
Time    : ${new Date()}
""".stripIndent()

        Mailer.send(email, "Nextflow workflow COMPLETED: ${workflow.runName}", msg)
    }
}

workflow.onError { wf, cause ->
    if (params.send_mail) {
        def email = params.email ?: "${System.getenv('USER') ?: 'unknown'}@exeter.ac.uk"
        def msg = """\
Workflow FAILED
Project : ${workflow.projectDir}
Run name: ${workflow.runName}
Time    : ${new Date()}
Error   : ${cause?.message ?: 'No message'}
""".stripIndent()

        Mailer.send(email, "Nextflow workflow FAILED: ${workflow.runName}", msg)
    }
}
