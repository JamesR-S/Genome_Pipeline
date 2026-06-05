import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardOpenOption

def resolveExistingFile(def pathLike) {
    def f = new File(pathLike.toString())
    return f.exists() ? file(f.toPath().toRealPath().toString()) : file(f.toString())
}

// --- Published-output status dictionary ---
def buildStatusById(List<List> rows, String batchDir) {
    def forceAll = params.rerun_all as boolean
    def skip_parliament = params.skip_parliament as boolean
    def skip_manta = params.skip_manta as boolean
    def skip_hla = params.skip_hla as boolean
    def align_only = params.align_only as boolean
    def metricsDir = "${batchDir}/r04_metrics"
    def statusById = [:]
    rows.each { row ->
        def id = row[0] as String
        if( statusById.containsKey(id) ) return
        def fam = row[3] as String
        def trio = row[4] as String

        // dependent on fq
        def cram = file("${batchDir}/r04_assembly/${id}.cram")
        def crai = file("${batchDir}/r04_assembly/${id}.cram.crai")
        def fq_qc = file("${batchDir}/r04_metrics/${id}_checkFastq.txt")

        // dependent on cram
        def dup_metrics = file("${batchDir}/r04_assembly/${id}.markdup_metrics")

        def cymegv_sample = file("${batchDir}/r04_cytomegalovirus/${id}_cytomegalovirus_grepped2.sam")
        def cymegv_batch = file("${batchDir}/r04_cytomegalovirus/stats")

        def TE_ALU = file("${batchDir}/r04_transposable_elements/${id}_ALU.vcf")
        def TE_L1 = file("${batchDir}/r04_transposable_elements/${id}_LINE1.vcf")
        def TE_SVA = file("${batchDir}/r04_transposable_elements/${id}_SVA.vcf")

        def snv_sample_vcf  = file("${batchDir}/r04_vcfs/${id}.vcf.gz")
        def snv_sample_csi  = file("${batchDir}/r04_vcfs/${id}.vcf.gz.csi")

        def snv_gvcf = file("${batchDir}/r04_gvcfs/${id}.g.vcf.gz")
        def snv_gvcf_csi = file("${batchDir}/r04_gvcfs/${id}.g.vcf.gz.csi")

        def hla_gvcf = file("${batchDir}/r04_hla_vcfs/${id}_hla.vcf.gz")
        def hla_vcf = file("${batchDir}/r04_hla_vcfs/${id}_hla.g.vcf.gz")

        def contam = file("${batchDir}/r04_metrics/${id}_cleanCall.csv")
        def contam_small = file("${batchDir}/r04_metrics/${id}_cleanCall_small.csv")

        def cov_binner = file("${batchDir}/r04_metrics/${id}.coverageBinner")

        def ins_size_stats = file("${batchDir}/r04_metrics/${id}.insertSize.stats")
        def ins_size_hist = file("${batchDir}/r04_metrics/${id}.insertSize.histogram")

        def clip_rate = file("${batchDir}/r04_metrics/${id}.clipRate") 

        def batch_cov_index = file("${batchDir}/r04_metrics/Coverage.indexed")

        def manta_cnv_vcf  = file("${batchDir}/r04_manta/${fam}.SV.vcf.gz")
        def manta_cnv_tbi  = file("${batchDir}/r04_manta/${fam}.SV.vcf.gz.tbi")

        def survindel = file("${batchDir}/r04_survindel2/${id}.genotyped.pass-ml.cnv.vcf.gz")

        def parliament = file("${batchDir}/r04_parliament2/${id}.combined.genotyped.vcf")

        def denovocnn = file("${batchDir}/r04_denovocnn/${trio}_denovos.filtered.txt")
        def denovoLI = file ("${batchDir}/r04_denovolargeinserts/${trio}.csv")

        def exphunter_locus = file("${batchDir}/r04_expansionhunterdenovo/${id}.locus.tsv")
        def exphunter_motif = file("${batchDir}/r04_expansionhunterdenovo/${id}.motif.tsv")
        def exphunter_profile = file("${batchDir}/r04_expansionhunterdenovo/${id}.str_profile.json")

        // dependent on gvcf

        def snv_fam_vcf = file("${batchDir}/r04_vcfs/${fam}.vcf.gz")
        def snv_fam_csi  = file("${batchDir}/r04_vcfs/${fam}.vcf.gz.csi")

        def ancestry = file("${batchDir}/r04_metrics/${id}.ancestry_assignment.tsv")

        // dependent on fam vcf

        def relatedness = file("${batchDir}/r04_metrics/relatedness2.csv")
        def batch_homoz = file("${batchDir}/r04_metrics/homozygosity.csv")

        def sample_homoz = file("${batchDir}/r04_metrics/${id}_homozygosity.csv")

        def vep = file("${batchDir}/r04_vep/${fam}_vep_annotated.vcf.gz")
        def vep_csi  = file("${batchDir}/r04_vep/${fam}_vep_annotated.vcf.gz.csi")

        // dependent on indexed coverage

        def cov_rep = file("${batchDir}/r04_metrics/coverage_report")

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
        def hla_needed = ((!hla_vcf.exists() || !hla_gvcf.exists() || forceAll) && !skip_hla) && !align_only
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
            cram: resolveExistingFile(cram),
            crai: resolveExistingFile(crai),
            fq_qc: resolveExistingFile(fq_qc),
            gvcf: resolveExistingFile(snv_gvcf),
            gvcf_csi: resolveExistingFile(snv_gvcf_csi),
            fam_vcf: resolveExistingFile(snv_fam_vcf),
            fam_vcf_csi: resolveExistingFile(snv_fam_csi),
            indexed_cov: resolveExistingFile(batch_cov_index)
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

def parseLineToTuple(String line, String batchDir) {
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
    def fq1 = file(batchDir+"/fastq/"+map.fastq1)
    def fq2 = file(batchDir+"/fastq/"+map.fastq2)
    
    return [ id, platform, sex, family, trio, flowcell, laneCount, famSampleCount, fq1, fq2 ]
}

def parseLineToTupleSpring(String line, String batchDir) {
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
    def spring     = file("${batchDir}/spring/${springName}")
    
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

def parseRequestedSampleIds(def raw) {
    if( raw == null ) return []
    def text = raw instanceof Collection ? raw.join(',') : raw.toString()
    def sampleIds = text
        .split(/[,\s]+/)
        .collect { it.trim() }
        .findAll { it }
    def deduped = []
    sampleIds.each { id ->
        if( !deduped.contains(id) ) deduped << id
    }
    return deduped
}

def parseRequestedTrios(def raw, Set<String> requestedIds = [] as Set) {
    def trioIds = parseRequestedSampleIds(raw)
    if( trioIds.isEmpty() ) return []

    if( trioIds.size() % 3 != 0 ) {
        throw new IllegalArgumentException(
            "--familyTrios must contain a multiple of 3 sample IDs, received ${trioIds.size()}: ${trioIds.join(', ')}"
        )
    }

    def trios = trioIds.collate(3)
    def invalidIds = requestedIds ? trios.flatten().findAll { !requestedIds.contains(it) } : []
    if( invalidIds ) {
        throw new IllegalArgumentException(
            "--familyTrios contains sample IDs not present in --familySampleIds: ${invalidIds.unique().join(', ')}"
        )
    }

    return trios
}

def assertSafeSampleIds(List<String> sampleIds) {
    def bad = sampleIds.findAll { !(it ==~ /[A-Za-z0-9._-]+/) }
    if( bad ) {
        throw new IllegalArgumentException("Invalid family sample ID(s): ${bad.join(', ')}")
    }
}

def listRemoteBatchDirs(String rootDir) {
    def root = new File(rootDir)
    if( !root.isDirectory() ) {
        throw new IllegalArgumentException("Family mode root does not exist: ${rootDir}")
    }

    def matches = []
    Files.newDirectoryStream(root.toPath(), 'WG*').withCloseable { outerDirs ->
        outerDirs.each { outerPath ->
            if( !Files.isDirectory(outerPath) ) return
            Files.newDirectoryStream(outerPath, 'WG*').withCloseable { innerDirs ->
                innerDirs.each { innerPath ->
                    if( Files.isDirectory(innerPath) ) {
                        matches << innerPath.toFile()
                    }
                }
            }
        }
    }

    return matches.sort { a, b -> a.absolutePath <=> b.absolutePath }
}

def inferSexBySampleFromControls(List<File> batchDirs) {
    def sexBySample = [:]
    batchDirs.each { batchDir ->
        def control = new File(batchDir, 'control')
        if( !control.exists() ) return

        def male = [] as Set
        def female = [] as Set
        control.eachLine { line ->
            def trimmed = line.trim()
            if( !trimmed ) return
            def tokens = trimmed.split(/\s+/)
            if( trimmed.startsWith('MALE') ) {
                male.addAll(tokens.size() > 1 ? tokens[1..-1] : [])
            } else if( trimmed.startsWith('FEMALE') ) {
                female.addAll(tokens.size() > 1 ? tokens[1..-1] : [])
            }
        }

        male.each { id ->
            def existing = sexBySample[id]
            if( existing && existing != 'male' ) {
                throw new IllegalStateException("Conflicting sex assignments found for ${id}")
            }
            sexBySample[id] = 'male'
        }
        female.each { id ->
            def existing = sexBySample[id]
            if( existing && existing != 'female' ) {
                throw new IllegalStateException("Conflicting sex assignments found for ${id}")
            }
            sexBySample[id] = 'female'
        }
    }
    return sexBySample
}

def inferTriosFromControls(List<File> batchDirs, Set<String> requestedIds) {
    def trios = [] as Set
    batchDirs.each { batchDir ->
        def control = new File(batchDir, 'control')
        if( !control.exists() ) return

        control.eachLine { line ->
            def trimmed = line.trim()
            if( !trimmed.startsWith('TRIO') ) return
            def tokens = trimmed.split(/\s+/)
            if( tokens.size() < 4 ) return
            def trioIds = tokens[1..3]
            if( trioIds.every { requestedIds.contains(it) } ) {
                trios << trioIds.join('-')
            }
        }
    }
    return trios.collect { it.tokenize('-') }.sort { a, b -> a.join('-') <=> b.join('-') }
}

def findSampleSourceBatch(String sampleId, List<File> batchDirs) {
    def matches = batchDirs.findAll { batchDir ->
        new File(batchDir, "r04_assembly/${sampleId}.cram").exists()
    }

    if( matches.size() != 1 ) {
        def found = matches ? matches*.absolutePath.join(', ') : 'none'
        throw new IllegalStateException(
            "Expected exactly one source batch with r04_assembly/${sampleId}.cram for ${sampleId} under ${params.familySourceRoot}, found: ${found}"
        )
    }
    return matches[0]
}

def ensureDir(File dir) {
    if( !dir.exists() && !dir.mkdirs() ) {
        throw new IllegalStateException("Could not create directory: ${dir}")
    }
}

def ensureSymlink(File dest, File src, boolean required=true) {
    if( !src.exists() ) {
        if( required ) {
            throw new IllegalStateException("Required source file is missing: ${src}")
        }
        return false
    }

    ensureDir(dest.parentFile)
    Path destPath = dest.toPath()
    Path srcPath = src.toPath()

    if( Files.exists(destPath) || Files.isSymbolicLink(destPath) ) {
        if( Files.isSymbolicLink(destPath) ) {
            def current = Files.readSymbolicLink(destPath)
            def currentAbs = destPath.parent.resolve(current).normalize()
            if( currentAbs == srcPath.toAbsolutePath().normalize() ) {
                return true
            }
        }
        Files.delete(destPath)
    }

    Files.createSymbolicLink(destPath, srcPath.toAbsolutePath())
    return true
}

def writeTextFile(File dest, String text) {
    ensureDir(dest.parentFile)
    Files.writeString(
        dest.toPath(),
        text,
        StandardOpenOption.CREATE,
        StandardOpenOption.TRUNCATE_EXISTING,
        StandardOpenOption.WRITE
    )
}

def buildFamilyModeBatch() {
    def familyMode = params.familyMode != null ? params.familyMode.toString().toBoolean() : false
    def skipHla = params.skip_hla as boolean
    if( !familyMode ) return null

    def sampleIds = parseRequestedSampleIds(params.familySampleIds ?: params.familySamples ?: params.samples)
    if( sampleIds.isEmpty() ) {
        throw new IllegalArgumentException(
            "Family mode requires --familySampleIds with a comma- or space-separated list of WG sample IDs"
        )
    }
    assertSafeSampleIds(sampleIds)

    def batchRoot = (params.familySourceRoot ?: '/ennis/projects/Research_Project-MRC147594') as String
    def familyBaseDir = (params.familyBaseDir ?: "${batchRoot}/families") as String
    def familyName = (params.familyName ?: sampleIds.join('-')) as String

    def batchDirs = listRemoteBatchDirs(batchRoot)
    def sexBySample = inferSexBySampleFromControls(batchDirs)
    def requestedSet = sampleIds as Set
    def inferredTrios = inferTriosFromControls(batchDirs, requestedSet)
    def explicitTrios = parseRequestedTrios(params.familyTrios, requestedSet)
    def trioList = explicitTrios ?: inferredTrios

    def familyDir = new File(familyBaseDir, familyName)
    ensureDir(familyDir)

    def sourceBatchById = [:]
    sampleIds.each { id ->
        sourceBatchById[id] = findSampleSourceBatch(id, batchDirs)
        if( !sexBySample[id] ) {
            throw new IllegalStateException("Could not determine sex for ${id} from source batch control files")
        }
    }

    def requiredLinks = [
        [dir:'r04_assembly',               file:{ id -> "${id}.cram" },                             required:true ],
        [dir:'r04_assembly',               file:{ id -> "${id}.cram.crai" },                        required:true ],
        [dir:'r04_metrics',                file:{ id -> "${id}_checkFastq.txt" },                   required:true ],
        [dir:'r04_assembly',               file:{ id -> "${id}.markdup_metrics" },                  required:true ],
        [dir:'r04_cytomegalovirus',        file:{ id -> "${id}_cytomegalovirus_grepped2.sam" },     required:true ],
        [dir:'r04_transposable_elements',  file:{ id -> "${id}_ALU.vcf" },                          required:true ],
        [dir:'r04_transposable_elements',  file:{ id -> "${id}_LINE1.vcf" },                        required:true ],
        [dir:'r04_transposable_elements',  file:{ id -> "${id}_SVA.vcf" },                          required:true ],
        [dir:'r04_vcfs',                   file:{ id -> "${id}.vcf.gz" },                           required:true ],
        [dir:'r04_vcfs',                   file:{ id -> "${id}.vcf.gz.csi" },                       required:true ],
        [dir:'r04_gvcfs',                  file:{ id -> "${id}.g.vcf.gz" },                         required:true ],
        [dir:'r04_gvcfs',                  file:{ id -> "${id}.g.vcf.gz.csi" },                     required:true ],
        [dir:'r04_hla_vcfs',               file:{ id -> "${id}_hla.g.vcf.gz" },                     required:!skipHla ],
        [dir:'r04_hla_vcfs',               file:{ id -> "${id}_hla.vcf.gz" },                       required:!skipHla ],
        [dir:'r04_metrics',                file:{ id -> "${id}.coverageBinner" },                   required:true ],
        [dir:'r04_metrics',                file:{ id -> "${id}.insertSize.stats" },                 required:true ],
        [dir:'r04_metrics',                file:{ id -> "${id}.insertSize.histogram" },             required:true ],
        [dir:'r04_metrics',                file:{ id -> "${id}.clipRate" },                         required:true ],
        [dir:'r04_survindel2',             file:{ id -> "${id}.genotyped.pass-ml.cnv.vcf.gz" },     required:true ],
        [dir:'r04_parliament2',            file:{ id -> "${id}.combined.genotyped.vcf" },           required:true ],
        [dir:'r04_expansionhunterdenovo',  file:{ id -> "${id}.locus.tsv" },                        required:true ],
        [dir:'r04_expansionhunterdenovo',  file:{ id -> "${id}.motif.tsv" },                        required:true ],
        [dir:'r04_expansionhunterdenovo',  file:{ id -> "${id}.str_profile.json" },                 required:true ],
        [dir:'r04_metrics',                file:{ id -> "${id}.ancestry_assignment.tsv" },          required:true ],
        [dir:'r04_hla_vcfs',               file:{ id -> "${id}_hla.g.vcf.gz.csi" },                 required:false ],
        [dir:'r04_hla_vcfs',               file:{ id -> "${id}_hla.vcf.gz.csi" },                   required:false ],
        [dir:'r04_metrics',                file:{ id -> "${id}_cleanCall.csv" },                    required:false ],
        [dir:'r04_metrics',                file:{ id -> "${id}_cleanCall_small.csv" },              required:false ]
    ]

    sampleIds.each { id ->
        def batchDir = sourceBatchById[id] as File
        requiredLinks.each { spec ->
            def relPath = "${spec.dir}/${spec.file(id)}"
            ensureSymlink(new File(familyDir, relPath), new File(batchDir, relPath), spec.required as boolean)
        }

        def contam = new File(familyDir, "r04_metrics/${id}_cleanCall.csv")
        def contamSmall = new File(familyDir, "r04_metrics/${id}_cleanCall_small.csv")
        if( !contam.exists() && !contamSmall.exists() ) {
            throw new IllegalStateException("Missing cleanCall output for ${id} in ${batchDir}")
        }
    }

    def males = sampleIds.findAll { sexBySample[it] == 'male' }
    def females = sampleIds.findAll { sexBySample[it] == 'female' }
    def controlLines = ['VERSION genome', '']
    if( males )   controlLines << "MALE ${males.join(' ')}"
    if( females ) controlLines << "FEMALE ${females.join(' ')}"
    controlLines << ''
    controlLines << "FAMILY ${sampleIds.join(' ')}"
    trioList.each { trioIds ->
        controlLines << "TRIO ${trioIds.join(' ')}"
    }
    controlLines << ''
    sampleIds.each { id ->
        controlLines << "FASTQ ${id} ILLUMINA FAMILYMODE ${id}_familymode_R1.fastq.gz ${id}_familymode_R2.fastq.gz"
    }
    controlLines << ''

    def manifestLines = sampleIds.collect { id ->
        "${id}\t${sexBySample[id]}\t${sourceBatchById[id].absolutePath}"
    }

    def controlFile = new File(familyDir, 'control')
    writeTextFile(controlFile, controlLines.join('\n'))
    writeTextFile(new File(familyDir, 'family_mode_sources.tsv'), "sample\tsex\tsource_batch\n${manifestLines.join('\n')}\n")

    return [
        batchDir : familyDir.absolutePath,
        control  : controlFile.absolutePath,
        family   : familyName,
        samples  : sampleIds,
        trios    : trioList
    ]
}


workflow HELPERS { }
