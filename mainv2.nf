#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { CONTROL_PARSER } from './modules/parse_control.nf'
include { CONTAM_SMALL } from './modules/clean_call_contamination.nf'
include { EXPANSION_HUNTER_DE_NOVO } from './modules/expansionHunterDeNovo.nf'
include { XTEA_ME } from './subworkflows/xtea_ME.nf'
include { TRIO_DE_NOVO } from './subworkflows/trio_de_novo.nf'
include { FASTQTOBAM } from './subworkflows/fastqtobam.nf'
include { SNV_INDEL_CALLING } from './subworkflows/snv_indel_calling.nf'
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
    def fastqFiles = [
       R1: file("fastq/"+map.fastq1),
       R2: file("fastq/"+map.fastq2)
    ]
    return [ id, platform, sex, family, trio, flowcell, laneCount, famSampleCount, fastqFiles ]
}

params.control = file(params.control ?: 'control')

workflow {

      ch_control = file(params.control)
      ch_ref_fasta = file(params.referenceFasta)
      ch_ref_fai = file(params.referenceFasta + ".fai")
      ch_ref_gff = file( params.referenceGFF )
      CONTROL_PARSER (ch_control)

      CONTROL_PARSER.out.reads
            .splitText()              
            .filter { it }            
            .map   { parseLineToTuple(it) }
            .set  { ch_parsed }

      FASTQTOBAM (ch_parsed)
            .out()
            .set { ch_final_bam }

      XTEA_ME (ch_final_bam, ch_ref_fasta, ch_ref_fai, ch_ref_gff)

      EXPANSION_HUNTER_DE_NOVO (ch_final_bam)

      CONTAM_SMALL (ch_final_bam)

      SNV_INDEL_CALLING(ch_final_bam, ch_ref_fasta, ch_ref_fai)

      TRIO_DE_NOVO (ch_final_bam, ch_ref_fasta, ch_ref_fai)
}
