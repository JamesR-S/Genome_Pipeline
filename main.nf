#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { CONTROL_PARSER } from './modules/parse_control.nf'
include { BWA_MEM } from './modules/bwa_mem.nf'
include { MERGE_SAMS } from './modules/merge_sam.nf'
include { FIXMATE } from './modules/fix_mate.nf'
include { MARKDUP } from './modules/mark_duplicates.nf'
include { INDEL_REALIGN } from './modules/realign_indels.nf'
include { CONTAM } from './modules/clean_call_contamination.nf'
include { CONTAM_SMALL } from './modules/clean_call_contamination.nf'
include { EXPANSION_HUNTER_DE_NOVO } from './modules/expansionHunterDeNovo.nf'
include { SCRAMBLE_CLUST_IDENT } from './modules/scramble.nf'
include { SPLIT_CLUST_FILE } from './modules/scramble.nf'
include { SCRAMBLE_CLUST_ANALYSIS } from './modules/scramble.nf'
include { CAT_CLUST_FILE } from './modules/scramble.nf'
include { DEEP_VARIANT } from './modules/deep_variant.nf'

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
        .view()
        .set  { ch_raw_sams }

  MERGE_SAMS (ch_raw_sams)
        .set  { ch_mi_bams }

  FIXMATE (ch_mi_bams)
        .set  { ch_fixmate }
  
  MARKDUP (ch_fixmate)
        .set  { ch_markdup }

  INDEL_REALIGN (ch_markdup)
        .set  { ch_final_bam }

  EXPANSION_HUNTER_DE_NOVO (ch_final_bam)

  CONTAM (ch_final_bam)  

  CONTAM_SMALL (ch_final_bam)

  SCRAMBLE_CLUST_IDENT (ch_final_bam)
         .set  { ch_scramble_ident }

  SPLIT_CLUST_FILE (ch_scramble_ident)
         .flatMap { sampleName, chunkFiles ->
           chunkFiles.sort().indexed().collect { idx, chunkFile ->
            [ sampleName, idx, chunkFile ]
            }
         }
         .set { ch_split_chunks }

  SCRAMBLE_CLUST_ANALYSIS (ch_split_chunks)
    .groupTuple(size: 5)
    .map { sampleName, chunkList ->
        def sorted = chunkList.sort { it[0] } 
        def chunkFiles = sorted.collect { it[1] } 
        [ sampleName, chunkFiles ]
    }
    .set { ch_grouped_chunks }

  CAT_CLUST_FILE (ch_grouped_chunks)

  ch_final_bam
    .filter { row -> row.trio != 'NA' }
    .map { row ->
            def (id, sex, family, trio, famSampleCount, bam_file ,bai_file) = row
            def key = [sex:sex, family:family, trio:trio, famSampleCount:famSampleCount]        
            tuple(key, [id:id, bam:bam_file, bai:bai_file])
        }
    .groupTuple(size: 3)
    .map { key, bam_bai -> tuple(key.getGroupTarget(), bam_bai)}  
        .view() 
        .set  { ch_trios }
}
