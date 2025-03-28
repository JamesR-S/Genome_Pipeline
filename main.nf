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
include { cleanCallContamination, cleanCallContaminationSmall } from './modules/clean_call_contamination.nf'

// Read the control file (default "control" unless specified)
params.control = file(params.control ?: 'control')
def control_data = parse_control(params.control)
println "Parsed ${control_data.samples.size()} samples from control file."
println "Found ${control_data.families.size()} families and ${control_data.trios.size()} trios."

// Create a channel from the list of sample maps
Channel.from( control_data.samples ).set { samples_ch }

workflow {

    // Step 1: Check FASTQ files
    checked_ch = samples_ch | checkFastq

    // Step 2: Run kevlar k-mer count (if desired)
    kevlar_ch = checked_ch | kevlarCount

    // Step 3: Align FASTQ files with bwa mem
    sam_ch = checked_ch | bwaMem

    // (Optionally merge SAM files if there are multiple per sample)
    // merged_ch = sam_ch | mergeSamFiles
    // For this example, we assume one SAM per sample:
    merged_ch = sam_ch

    // Step 4: Fix mate information using Picard
    fixmate_ch = merged_ch | fixMate

    // Step 5: Mark duplicates using Picard
    dedup_ch = fixmate_ch | markDuplicates

    // Step 6: Realign indels (GATK)
    realigned_ch = dedup_ch | realignIndels

    // Step 7: Run the two cleanCall-contamination scripts
    cleanCall_ch = realigned_ch | cleanCallContamination
    cleanCallSmall_ch = realigned_ch | cleanCallContaminationSmall

    // For demonstration, print out the final realigned BAM file for each sample:
    realigned_ch.view { sampleName, bam -> println "Final processed BAM for sample ${sampleName}: ${bam}" }

    // Additional downstream grouping can be done using control_data.families and control_data.trios.
}
