// --- Published-output status dictionary ---
def buildStatusById(List<List> rows) {
    def forceAll = params.rerun_all as boolean
    def skip_parliament = params.skip_parliament as boolean
    def skip_manta = params.skip_manta as boolean
    def align_only = params.align_only as boolean
    def metricsDir = "${params.batchDir}/r04_metrics"
    def statusById = [:]
    rows.each { row ->
        def id = row[0] as String
        if( statusById.containsKey(id) ) return
        def fam = row[3] as String
        def trio = row[4] as String

        // dependent on fq
        def cram = file("${params.batchDir}/r04_assembly/${id}.cram")
        def crai = file("${params.batchDir}/r04_assembly/${id}.cram.crai")
        def fq_qc = file("${params.batchDir}/r04_metrics/${id}_checkFastq.txt")

        // dependent on cram
        def dup_metrics = file("${params.batchDir}/r04_assembly/${id}.markdup_metrics")

        def cymegv_sample = file("${params.batchDir}/r04_cytomegalovirus/${id}_cytomegalovirus_grepped2.sam")
        def cymegv_batch = file("${params.batchDir}/r04_cytomegalovirus/stats")

        def TE_ALU = file("${params.batchDir}/r04_transposable_elements/${id}_ALU.vcf")
        def TE_L1 = file("${params.batchDir}/r04_transposable_elements/${id}_LINE1.vcf")
        def TE_SVA = file("${params.batchDir}/r04_transposable_elements/${id}_SVA.vcf")

        def snv_sample_vcf  = file("${params.batchDir}/r04_vcfs/${id}.vcf.gz")
        def snv_sample_csi  = file("${params.batchDir}/r04_vcfs/${id}.vcf.gz.csi")

        def snv_gvcf = file("${params.batchDir}/r04_gvcfs/${id}.g.vcf.gz")
        def snv_gvcf_csi = file("${params.batchDir}/r04_gvcfs/${id}.g.vcf.gz.csi")

        def hla_gvcf = file("${params.batchDir}/r04_hla_vcfs/${id}_hla.vcf.gz")
        def hla_vcf = file("${params.batchDir}/r04_hla_vcfs/${id}_hla.g.vcf.gz")

        def contam = file("${params.batchDir}/r04_metrics/${id}_cleanCall.csv")
        def contam_small = file("${params.batchDir}/r04_metrics/${id}_cleanCall_small.csv")

        def cov_binner = file("${params.batchDir}/r04_metrics/${id}.coverageBinner")

        def ins_size_stats = file("${params.batchDir}/r04_metrics/${id}.insertSize.stats")
        def ins_size_hist = file("${params.batchDir}/r04_metrics/${id}.insertSize.histogram")

        def clip_rate = file("${params.batchDir}/r04_metrics/${id}.clipRate") 

        def batch_cov_index = file("${params.batchDir}/r04_metrics/Coverage.indexed")

        def manta_cnv_vcf  = file("${params.batchDir}/r04_manta/${fam}.SV.vcf.gz")
        def manta_cnv_tbi  = file("${params.batchDir}/r04_manta/${fam}.SV.vcf.gz.tbi")

        def survindel = file("${params.batchDir}/r04_survindel2/${id}.genotyped.pass-ml.cnv.vcf.gz")

        def parliament = file("${params.batchDir}/r04_parliament2/${id}.combined.genotyped.vcf")

        def denovocnn = file("${params.batchDir}/r04_denovocnn/${trio}_denovos.filtered.txt")
        def denovoLI = file ("${params.batchDir}/r04_denovolargeinserts/${trio}.csv")

        def exphunter_locus = file("${params.batchDir}/r04_expansionhunterdenovo/${id}.locus.tsv")
        def exphunter_motif = file("${params.batchDir}/r04_expansionhunterdenovo/${id}.motif.tsv")
        def exphunter_profile = file("${params.batchDir}/r04_expansionhunterdenovo/${id}.str_profile.json")

        // dependent on gvcf

        def snv_fam_vcf = file("${params.batchDir}/r04_vcfs/${fam}.vcf.gz")
        def snv_fam_csi  = file("${params.batchDir}/r04_vcfs/${fam}.vcf.gz.csi")

        def ancestry = file("${params.batchDir}/r04_metrics/${id}.ancestry_assignment.tsv")

        // dependent on fam vcf

        def relatedness = file("${params.batchDir}/r04_metrics/relatedness2.csv")
        def batch_homoz = file("${params.batchDir}/r04_metrics/homozygosity.csv")

        def sample_homoz = file("${params.batchDir}/r04_metrics/${id}_homozygosity.csv")

        def vep = file("${params.batchDir}/r04_vep/${fam}_vep_annotated.vcf.gz")
        def vep_csi  = file("${params.batchDir}/r04_vep/${fam}_vep_annotated.vcf.gz.csi")

        // dependent on indexed coverage

        def cov_rep = file("${params.batchDir}/r04_metrics/coverage_report")

        def qc_needed = (!fq_qc.exists() || forceAll) && !align_only
        def cram_needed = !cram.exists() || !crai.exists() || forceAll
        def dup_metrics_needed = (!dup_metrics.exists() || forceAll) && !align_only
        def cymegv_needed = (!cymegv_sample.exists() || !cymegv_batch.exists() || forceAll) && !align_only
        def te_needed = (!TE_ALU.exists() || !TE_L1.exists() || !TE_SVA.exists() || forceAll) && !align_only
        def snv_needed = (!snv_sample_vcf.exists() || !snv_sample_csi.exists() || !snv_gvcf.exists() || !snv_gvcf_csi.exists() || forceAll) && !align_only
        def contam_needed = (!contam.exists() && !contam_small.exists() || forceAll) && !align_only
        def cov_needed = (!cov_binner.exists() || !ins_size_stats.exists() || !ins_size_hist.exists() || !clip_rate.exists() || !batch_cov_index.exists() || forceAll) && !align_only
        def cnv_needed = ((!manta_cnv_vcf.exists() || !manta_cnv_tbi.exists() || forceAll) && !skip_manta) && !align_only
        def survindel_needed = (!survindel.exists() || forceAll) && !align_only
        def parliament_needed = (( !parliament.exists() || forceAll ) && !skip_parliament) && !align_only
        def denovocnn_needed = ((!denovocnn.exists() || forceAll ) && trio != "NA") && !align_only
        def denovoLI_needed = ((!denovoLI.exists() || forceAll) && trio != "NA") && !align_only
        def exphunter_needed = (!exphunter_locus.exists() || !exphunter_motif.exists() || !exphunter_profile.exists() || forceAll) && !align_only
        def fam_vcf_needed = (!snv_fam_vcf.exists() || !snv_fam_csi.exists() || forceAll) && !align_only
        def ancestry_needed = (!ancestry.exists() || forceAll) && !align_only
        def relatedness_needed = (!relatedness.exists() || forceAll) && !align_only
        def batch_homoz_needed = (!batch_homoz.exists() || forceAll) && !align_only
        def hla_needed = (!hla_vcf.exists() || !hla_gvcf.exists() || forceAll) && !align_only
        def sample_homoz_needed = (!sample_homoz.exists() || forceAll) && !align_only
        def vep_needed = (!vep.exists() || !vep_csi.exists() || forceAll) && !align_only
        def bam_needed = (dup_metrics_needed || cymegv_needed || te_needed || snv_needed || cov_needed || cnv_needed || survindel_needed || parliament_needed || exphunter_needed || contam_needed || denovocnn_needed || denovoLI_needed || hla_needed || forceAll) && !align_only
        def upd_needed = (!allPairFilesExist(fam, metricsDir, '_UPD.csv', true) || forceAll) && !align_only
        def shared_haps_needed = (!allPairFilesExist(fam, metricsDir, '_homozygosity.csv', false) || forceAll) && !align_only

        statusById[id] = [
            qc_needed: qc_needed,
            cram_needed: cram_needed,
            bam_needed: bam_needed,
            dup_metrics_needed: dup_metrics_needed,
            cymegv_needed: cymegv_needed,
            te_needed: te_needed,
            snv_needed: snv_needed,
            hla_needed: hla_needed,
            contam_needed: contam_needed,
            cov_needed: cov_needed,
            cnv_needed: cnv_needed,
            survindel_needed: survindel_needed,
            parliament_needed: parliament_needed,
            denovocnn_needed: denovocnn_needed,
            denovoLI_needed: denovoLI_needed,
            exphunter_needed: exphunter_needed,
            fam_vcf_needed: fam_vcf_needed,
            ancestry_needed: ancestry_needed,
            relatedness_needed: relatedness_needed,
            batch_homoz_needed: batch_homoz_needed,
            sample_homoz_needed: sample_homoz_needed,
            shared_haps_needed: shared_haps_needed,
            upd_needed: upd_needed,
            vep_needed: vep_needed,
            cram: cram,
            crai: crai,
            fq_qc: fq_qc,
            gvcf: snv_gvcf,
            gvcf_csi: snv_gvcf_csi,
            fam_vcf: snv_fam_vcf,
            fam_vcf_csi: snv_fam_csi,
            indexed_cov: batch_cov_index
        ]
    }
    return statusById
}

def parseLineToMeta(String line) {
    def pairs = line.split(/;/)
    def map = [:]
    pairs.each { kv ->
        def (k,v) = kv.split(/=/,2)
        map[k.trim()] = v.trim()
    }

    def id = map.sample
    return [
        id            : id,
        platform      : map.platform,
        sex           : map.sex,
        family        : map.family,
        trio          : map.trio,
        flowcell      : map.flowcell,
        laneCount     : map.sampleLaneCount.toInteger(),
        famSampleCount: map.familySampleCount.toInteger()
    ]
}

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
    int i = 0
    while (i < fq1_name.size() && i < fq2_name.size() && fq1_name[i] == fq2_name[i]) {
        i++
    }
    def common = fq1_name[0..<i].replaceFirst(/[_\.\-(_R)]+$/, '')  // trim trailing _.- if wanted

    def springName = "${common}.spring"
    def spring     = file("${params.batchDir}/spring/${springName}")
    
        return [ id, platform, sex, family, trio, flowcell, laneCount, famSampleCount, spring ]
}

def makeParsedLines(File controlFile) {
    def families = []
    def trios    = []
    def maleList = []
    def femaleList = []
    def fastqRecords = []
    def sampleSet = new HashSet<String>()

    controlFile.eachLine { line ->
        line = line.trim()
        if(!line) return
        def tokens = line.split(/\s+/)
        if(line.startsWith("FAMILY")) {
            families << tokens[1..-1]
        } else if(line.startsWith("TRIO")) {
            trios << tokens[1..-1]
        } else if(line.startsWith("MALE")) {
            maleList.addAll(tokens[1..-1])
        } else if(line.startsWith("FEMALE")) {
            femaleList.addAll(tokens[1..-1])
        } else if(line.startsWith("FASTQ")) {
            fastqRecords << [sample:tokens[1], platform:tokens[2], flowcell:tokens[3], fastq1:tokens[4], fastq2:tokens[5]]
            sampleSet << tokens[1]
        } else if(line.startsWith("SPRING")) {
            def base = tokens[4].replaceAll(/\.spring$/, '')
            fastqRecords << [sample:tokens[1], platform:tokens[2], flowcell:tokens[3], fastq1:base, fastq2:base]
            sampleSet << tokens[1]
        }
    }

    def familyDict = [:].withDefault{ new HashSet<String>() }
    families.each { famLine ->
        def famName = famLine.join('-')
        familyDict[famName].addAll(famLine)
    }

    def trioDict = [:].withDefault{ new HashSet<String>() }
    trios.each { triLine ->
        def trioName = triLine.join('-')
        trioDict[trioName].addAll(triLine)
    }

    def laneCounts = [:].withDefault{0}
    fastqRecords.each { rec -> laneCounts[rec.sample] = laneCounts[rec.sample] + 1 }

    def familySizes = [:]
    familyDict.each { fname, members -> familySizes[fname] = members.size() }

    def getSex = { String s ->
        def isMale = maleList.contains(s)
        def isFemale = femaleList.contains(s)
        if(isMale && isFemale) return "conflict"
        if(isMale) return "male"
        if(isFemale) return "female"
        return "NA"
    }

    def getFamily = { String s ->
        def found = familyDict.find { k,v -> v.contains(s) }
        return found ? found.key : "NA"
    }

    def getTrio = { String s ->
        def found = trioDict.find { k,v -> v.contains(s) }
        return found ? found.key : "NA"
    }

    // Produce the same parsed lines format as CONTROL_PARSER
    def lines = []
    fastqRecords.each { rec ->
        def s = rec.sample
        def sex = getSex(s)
        def fam = getFamily(s)
        def trio = getTrio(s)
        def laneCount = laneCounts[s]
        def famCount  = (fam != "NA") ? (familySizes[fam] ?: 0) : 0

        lines << (
            "sample=${s};" +
            "platform=${rec.platform};" +
            "flowcell=${rec.flowcell};" +
            "sex=${sex};" +
            "family=${fam};" +
            "trio=${trio};" +
            "fastq1=${rec.fastq1};" +
            "fastq2=${rec.fastq2};" +
            "sampleLaneCount=${laneCount};" +
            "familySampleCount=${famCount}"
        )
    }
    return lines
}

/**
 * Build the list of expected UPD files for a family.
 * - orderedPairs=true matches your current bash loop (A-B and B-A).
 * - orderedPairs=false expects only i<j (A-B once).
 */
def expectedPairFiles(String family, String outDir, String suffix='_UPD.csv', boolean orderedPairs=true) {
    def ids = (family ?: '')
        .tokenize('-')
        .findAll { it }        // drop blanks
        .unique()              // safety; shouldn't happen but harmless

    def files = []
    if( orderedPairs ) {
        ids.each { a ->
            ids.each { b ->
                if( a == b ) return
                files << file("${outDir}/${a}-${b}${suffix}")
            }
        }
    } else {
        for( int i=0; i<ids.size(); i++ ) {
            for( int j=i+1; j<ids.size(); j++ ) {
                files << file("${outDir}/${ids[i]}-${ids[j]}${suffix}")
            }
        }
    }
    return files
}

/** True if ALL expected pair files exist; false if any are missing. */
def allPairFilesExist(String family, String outDir, String suffix='_UPD.csv', boolean orderedPairs=true) {
    def expected = expectedPairFiles(family, outDir, suffix, orderedPairs)
    return expected.every { it.exists() }
}

/** Return missing files (useful for debugging) */
def missingPairFiles(String family, String outDir, String suffix='_UPD.csv', boolean orderedPairs=true) {
    def expected = expectedPairFiles(family, outDir, suffix, orderedPairs)
    return expected.findAll { !it.exists() }
}


workflow HELPERS { }