// --- Published-output status dictionary ---
def buildStatusById(List<List> rows) {
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

        def contam = file("${params.batchDir}/r04_metrics/${id}_cleanCall.csv")
        def contam_small = file("${params.batchDir}/r04_metrics/${id}_cleanCall_small.csv")

        def cov_binner = file("${params.batchDir}/r04_metrics/${id}.coverageBinner")

        def ins_size_stats = file("${params.batchDir}/r04_metrics/${id}.insertSize.stats")
        def ins_size_hist = file("${params.batchDir}/r04_metrics/${id}.insertSize.histogram")

        def clip_rate = file("${params.batchDir}/r04_metrics/${id}.insertSize.clipRate") 

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

        def vep = file("${params.batchDir}/r04_vep/${id}_vep_annotated.vcf.gz")
        def vep_csi  = file("${params.batchDir}/r04_vep/${id}_vep_annotated.vcf.gz.csi")

        // dependent on indexed coverage

        def cov_rep = file("${params.batchDir}/r04_metrics/coverage_report")

        def qc_needed = !fq_qc.exists()
        def cram_needed = !cram.exists() || !crai.exists()
        def dup_metrics_needed = !dup_metrics.exists()
        def cymegv_needed = !cymegv_sample.exists() || !cymegv_batch.exists()
        def te_needed = !TE_ALU.exists() || !TE_L1.exists() || !TE_SVA.exists()
        def snv_needed = !snv_sample_vcf.exists() || !snv_sample_csi.exists() || !snv_gvcf.exists() || !snv_gvcf_csi.exists()
        def contam_needed = !contam.exists() && !contam_small.exists()
        def cov_needed = !cov_binner.exists() || !ins_size_stats.exists() || !ins_size_hist.exists() || !clip_rate.exists() || !batch_cov_index.exists()
        def cnv_needed = !manta_cnv_vcf.exists() || !manta_cnv_tbi.exists()
        def survindel_needed = !survindel.exists()
        def parliament_needed = !parliament.exists()
        def denovocnn_needed = !denovocnn.exists() && trio != "NA"
        def denovoLI_needed = !denovoLI.exists() && trio != "NA"
        def exphunter_needed = !exphunter_locus.exists() || !exphunter_motif.exists() || !exphunter_profile.exists()
        def fam_vcf_needed = !snv_fam_vcf.exists() || !snv_fam_csi.exists()
        def ancestry_needed = !ancestry.exists()
        def relatedness_needed = !relatedness.exists()
        def batch_homoz_needed = !batch_homoz.exists() 
        def sample_homoz_needed = !sample_homoz.exists()
        def vep_needed = !vep.exists() || !vep_csi.exists()
        def bam_needed = dup_metrics_needed || cymegv_needed || te_needed || snv_needed || cov_needed || cnv_needed || survindel_needed || parliament_needed || exphunter_needed || contam_needed || denovocnn_needed || denovoLI_needed 

        statusById[id] = [
            qc_needed: qc_needed,
            cram_needed: cram_needed,
            bam_needed: bam_needed,
            dup_metrics_needed: dup_metrics_needed,
            cymegv_needed: cymegv_needed,
            te_needed: te_needed,
            snv_needed: snv_needed,
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

workflow HELPERS { }