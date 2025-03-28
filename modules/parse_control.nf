#!/usr/bin/env groovy
// modules/parse_control.nf

def parse_control( controlFile ) {
    def samples = []      // Each sample: [name, platform, flowcell, fastq1, fastq2]
    def families = []     // Each family is a list of sample names
    def trios = []        // Each trio: [proband, father, mother]
    def maleSamples = []  // (Optional) List of male sample names
    def femaleSamples = []// (Optional) List of female sample names

    controlFile.eachLine { line ->
        line = line.trim()
        if( line.startsWith('FASTQ ') ) {
            def tokens = line.split(/\s+/)
            if( tokens.size() < 6 )
                error "FASTQ line has too few columns: ${line}"
            samples << [ name: tokens[1], platform: tokens[2], flowcell: tokens[3], fastq1: tokens[4], fastq2: tokens[5] ]
        }
        else if( line.startsWith('FAMILY ') ) {
            def tokens = line.split(/\s+/)
            families << tokens[1..-1]
        }
        else if( line.startsWith('TRIO ') ) {
            def tokens = line.split(/\s+/)
            if( tokens.size() < 4 )
                error "TRIO line has too few columns: ${line}"
            trios << [ proband: tokens[1], father: tokens[2], mother: tokens[3] ]
        }
        else if( line.startsWith('MALE ') ) {
            def tokens = line.split(/\s+/)
            maleSamples.addAll( tokens[1..-1] )
        }
        else if( line.startsWith('FEMALE ') ) {
            def tokens = line.split(/\s+/)
            femaleSamples.addAll( tokens[1..-1] )
        }
    }
    return [ samples: samples, families: families, trios: trios, male: maleSamples, female: femaleSamples ]
}

return this
