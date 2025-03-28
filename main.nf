#!/usr/bin/env nextflow

// Include the control file parser (written in Groovy)
include { parse_control }         from './modules/parse_control.nf'
// Include our bash‐based tool modules
include { checkFastq }            from './modules/check_fastq.nf'
include { kevlarCount }           from './modules/kevlar_count.nf'
include { bwaMem }                from './modules/bwa_mem.nf'
include { fixMate }               from './modules/fix_mate.nf'
include { markDuplicates }        from './modules/mark_duplicates.nf'
include { realignIndels }         from './modules/realign_indels.nf'
include { mergeSamFiles }         from './modules/merge_sam.nf'  // if needed
include { cleanCallContamination } from './modules/clean_call_contamination.nf'
include { cleanCallContaminationSmall } from './modules/clean_call_contamination.nf'

// Parse the control file (default "control" unless specified)
params.control = file(params.control ?: 'control')
def control_data = parse_control(params.control)
println "Parsed ${control_data.samples.size()} samples, ${control_data.families.size()} families, and ${control_data.trios.size()} trios."

// Create a channel from the list of sample maps
def samples_ch = Channel.from(control_data.samples)

workflow {

  // Per-sample processing:
  def checked_ch   = checkFastq(samples_ch)
  def kevlar_ch    = kevlarCount(checked_ch)
  def sam_ch       = bwaMem(checked_ch)
  
  // If a sample produces >1 SAM file, merge them (optional)
  // def merged_ch = mergeSamFiles(sam_ch)
  // For this example assume one SAM per sample:
  def merged_ch    = sam_ch
  
  def fixmate_ch   = fixMate(merged_ch)
  def dedup_ch     = markDuplicates(fixmate_ch)
  def realigned_ch = realignIndels(dedup_ch)
  def cleanCall_ch = cleanCallContamination(realigned_ch)
  def cleanCallSmall_ch = cleanCallContaminationSmall(realigned_ch)
  
  // For demonstration, print final per-sample outputs:
  realigned_ch.view { sampleName, bam -> println "Final BAM for sample ${sampleName}: ${bam}" }
}