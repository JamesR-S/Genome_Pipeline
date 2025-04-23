#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { CONTROL_PARSER } from './modules/parse_control.nf'
include { BWA_MEM } from './modules/bwa_mem.nf'
include { MERGE_SAMS } from './modules/merge_sam.nf'
include { FIXMATE } from './modules/fix_mate.nf'
include { MARKDUP } from './modules/mark_duplicates.nf'
include { CONTAM_SMALL } from './modules/clean_call_contamination.nf'
include { EXPANSION_HUNTER_DE_NOVO } from './modules/expansionHunterDeNovo.nf'
include { DEEP_VARIANT } from './modules/deep_variant.nf'
include { GLNEXUS } from './modules/glnexus.nf'
include { DEEP_TRIO } from './modules/deep_trio.nf'
include { DEEP_TRIO_DENOVO } from './modules/deep_trio.nf'
include { MOBILE_ELEMENTS } from './subworkflows/xtea_ME.nf'

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
        .set  { ch_mi_bams }

  FIXMATE (ch_mi_bams)
        .set  { ch_fixmate }
  
  MARKDUP (ch_fixmate)
        .set  { ch_final_bam }

  MOBILE_ELEMENTS (ch_final_bam, ch_ref_fasta, ch_ref_fai, ch_ref_gff)

  EXPANSION_HUNTER_DE_NOVO (ch_final_bam)

  CONTAM_SMALL (ch_final_bam)

  ch_final_bam
    .filter { row -> row[3] != 'NA' }
    .map { row ->
            def (id, sex, family, trio, famSampleCount, bam_file ,bai_file) = row
            def key = [family:family, trio:trio, famSampleCount:famSampleCount]        
            tuple(key, [id:id,sex:sex, bam:bam_file, bai:bai_file])
        }
    .groupTuple(size: 3)
    .map { key, bam_bai -> 
            def meta = key
            def orderedIds = meta.trio.tokenize('-')
            def idToIndex = orderedIds.collectEntries { famId ->
            [(famId): orderedIds.indexOf(famId)]
            }
            def sortedGroup = bam_bai.sort { rec ->
            idToIndex[rec.id]
            }
            def sortedIds  = sortedGroup*.id
            def sortedSex      = sortedGroup*.sex         
            def sortedbams = sortedGroup*.bam
            def sortedbais = sortedGroup*.bai
            tuple(sortedIds, sortedSex,meta.trio.tokenize('-'), sortedbams, sortedbais)
            }  
    .set { ch_trios_bam }


  DEEP_TRIO (ch_trios_bam, ch_ref_fasta, ch_ref_fai)
    .set{ ch_deep_trios }

  DEEP_TRIO_DENOVO (ch_deep_trios)

  DEEP_VARIANT (ch_final_bam, ch_ref_fasta, ch_ref_fai)

  DEEP_VARIANT.out.vcf.set { ch_vcf }
  DEEP_VARIANT.out.gvcf
    .filter { row -> row[4] >= 2 }
    .map {row ->
            def (id, sex, family, famSampleCount, gvcf, gvcfcsi) = row
            def key = [family:family, famSampleCount:famSampleCount]
            def gKey = groupKey(key, famSampleCount)          
            tuple(gKey, [id:id,sex:sex, gvcf:gvcf, gvcfcsi:gvcfcsi])
        }
    .groupTuple() 
    .map { key, gvcfs -> 
            def meta = key.getGroupTarget()
            def orderedIds = meta.family.tokenize('-')
            def idToIndex = orderedIds.collectEntries { famId ->
            [(famId): orderedIds.indexOf(famId)]
            }
            def sortedGroup = gvcfs.sort { rec ->
            idToIndex[rec.id]
            }
            def sortedIds      = sortedGroup*.id
            def sortedSex      = sortedGroup*.sex        
            def sortedGvcfs    = sortedGroup*.gvcf
            def sortedGvcfCsis = sortedGroup*.gvcfcsi
            tuple(sortedIds, sortedSex,meta.family,meta.famSampleCount, sortedGvcfs, sortedGvcfCsis)
            }
    .set  { family_gvcf }

    GLNEXUS (family_gvcf)

}
