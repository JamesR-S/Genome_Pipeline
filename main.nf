#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { CONTROL_PARSER } from './modules/parse_control.nf'
include { BWA_MEM } from './modules/bwa_mem.nf'
include { MERGE_SAMS } from './modules/merge_sam.nf'
include { FIXMATE } from './modules/fix_mate.nf'
include { MARKDUP } from './modules/mark_duplicates.nf'
include { INDEL_REALIGN } from './modules/realign_indels.nf'

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
    def family = map.family != 'NA' ? map.family.split(',') : 'NA'
    def trio = map.trio != 'NA' ? map.trio.split(',') : 'NA'
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


  CONTROL_PARSER (ch_control)

  CONTROL_PARSER.out.reads
        .splitText()              
        .filter { it }            
        .map   { parseLineToTuple(it) }
        .set  { ch_parsed }

  BWA_MEM (ch_parsed)
        .map { row ->
            def (id, sex, family, trio, laneCount, famSampleCount, sam_file) = row
            def key = [id:id, sex:sex, family:family, trio:trio, famSampleCount:famSampleCount]
            def gKey = groupKey(key, laneCount)          
            tuple(gKey, sam_file)
        }
        .groupTuple() 
        .map { key, sam_file -> tuple(key.getGroupTarget(), sam_file) }
        .set  { ch_raw_sams }

  MERGE_SAMS (ch_raw_sams)
        .set  { ch_mi_sams }

  FIXMATE (ch_mi_sams)
        .set  { ch_fixmate }
  
  MARKDUP (ch_fixmate)
        .set  { ch_markdup }

  INDEL_REALIGN (ch_markdup)
        .set  { ch_final_bam }  

  ch_final_bam
    .filter { row -> row.trio != 'NA' }
    .map { row ->
            def (id, sex, family, trio, famSampleCount, bam_file ,bai_file) = row
            def key = [sex:sex, family:family, trio:trio, famSampleCount:famSampleCount]        
            tuple(key, [id:id, bam:bam_file, bai:bai_file])
        }
    .groupTuple()
    .map { key, bam_bai -> tuple(key.getGroupTarget(), bam_bai) }
        .set  { ch_trios }
}
