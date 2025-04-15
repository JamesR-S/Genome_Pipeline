#!/usr/bin/env nextflow
nextflow.enable.dsl=2

include { CONTROL_PARSER } from './modules/parse_control.nf'
include { BWA_MEM } from './modules/bwa_mem.nf'
include { MERGE_SAMS } from './modules/merge_sam.nf'

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
       R1 = file("fastq/"+map.fastq1),
       R2 = file("fastq/"+map.fastq2)
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

  BWA-MEM (ch_parsed)
        .out
        .flatMap { row ->
        tuple(
          groupKey(row.id, row.laneCount),
          row
        )
        }
        .groupTuple() 
        .map { key, row -> tuple(key.getGroupTarget(), row) }
        .set  { ch_sams }

  MERGE-SAMS (ch_sams)
}
