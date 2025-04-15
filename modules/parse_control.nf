process CONTROL_PARSER {
    tag "$controlFile"
    executor: 'local'
    input:
      path controlFile

    output:
      path "parsed_lines.txt", emit: reads
      path "versions.yml",      emit: versions

    script:
    """
    python <<EOF
import sys
from collections import defaultdict

families     = []    # will hold lines like ["FAM1","SAMPLE_A","SAMPLE_B",...]
trios        = []    # will hold lines like ["T1","SAMPLE_X","SAMPLE_Y","SAMPLE_Z",...]
maleList     = []
femaleList   = []
fastqRecords = []    # raw FASTQ lines
sampleSet    = set() # keep track of all sample names we see
                 

with open("${controlFile}", "r") as fh:
    for line in fh:
        line = line.strip()
        if not line:
            continue
        tokens = line.split()
        if line.startswith("FAMILY"):
            # e.g. "FAMILY FAM1 WG1744 WG1745 WG1746"
            families.append(tokens[1:])  # ["FAM1","WG1744","WG1745","WG1746"]
        elif line.startswith("TRIO"):
            # e.g. "TRIO T1 SAMPLE_A SAMPLE_B SAMPLE_C"
            trios.append(tokens[1:])     # ["T1","SAMPLE_A","SAMPLE_B","SAMPLE_C"]
        elif line.startswith("MALE"):
            # e.g. "MALE WG1744 WG1746"
            maleList.extend(tokens[1:])
        elif line.startswith("FEMALE"):
            # e.g. "FEMALE WG1745 WG1747"
            femaleList.extend(tokens[1:])
        elif line.startswith("FASTQ"):
            # e.g. "FASTQ SAMPLE_A ILLUMINA FC001 R1.fq.gz R2.fq.gz"
            # tokens: [FASTQ, sample, platform, flowcell, fastq1, fastq2]
            record = {
                "sample"  : tokens[1],
                "platform": tokens[2],
                "flowcell": tokens[3],
                "fastq1"  : tokens[4],
                "fastq2"  : tokens[5]
            }
            fastqRecords.append(record)
            sampleSet.add(tokens[1])

# ----------------------------
# Build a dictionary: family -> set of samples
# Each line in families looks like: [famName, sampleA, sampleB, ...]
# So familyDict["FAM1"] = {"WG1744","WG1745","WG1746"}
familyDict = {}
for famLine in families:
    famName = famLine[0]
    samples = famLine[1:]
    familyDict.setdefault(famName, set()).update(samples)

# Build a dictionary: trio -> set of samples
trioDict = {}
for triLine in trios:
    trioName = triLine[0]
    samples  = triLine[1:]
    trioDict.setdefault(trioName, set()).update(samples)

# Build a dictionary: sample -> count of FASTQ records (lanes)
sampleLaneCounts = defaultdict(int)
for rec in fastqRecords:
    sampleLaneCounts[rec["sample"]] += 1

# Build a dictionary: family -> # samples in that family
# We'll look at all families we found; size = number of unique samples
familySizes = { fname: len(sampleSet) for fname, sampleSet in familyDict.items() }

def getSex(sample):
    isMale   = (sample in maleList)
    isFemale = (sample in femaleList)
    if isMale and isFemale:
        return "conflict"
    elif isMale:
        return "male"
    elif isFemale:
        return "female"
    else:
        return "NA"

def getFamily(sample):
    # Return the first family name in which this sample appears, else "NA"
    for fname, members in familyDict.items():
        if sample in members:
            return fname
    return "NA"

def getTrio(sample):
    # Return the first trio name in which this sample appears, else "NA"
    for tname, members in trioDict.items():
        if sample in members:
            return tname
    return "NA"

with open("parsed_lines.txt", "w") as outFile:
    for rec in fastqRecords:
        s       = rec["sample"]
        sex     = getSex(s)
        fam     = getFamily(s)
        trio    = getTrio(s)
        # lookup the lane count for this sample
        laneCount = sampleLaneCounts[s]
        # lookup how many samples in the family, or 0 if not found
        famCount  = familySizes.get(fam, 0) if fam != "NA" else 0

        # Now write out the key=value pairs
        # We'll add sampleLaneCount, familySampleCount, trioSampleCount
        line = (
            f"sample={s};"
            f"platform={rec['platform']};"
            f"flowcell={rec['flowcell']};"
            f"sex={sex};"
            f"family={fam};"
            f"trio={trio};"
            f"fastq1={rec['fastq1']};"
            f"fastq2={rec['fastq2']};"
            f"sampleLaneCount={laneCount};"
            f"familySampleCount={famCount}"
        )
        outFile.write(line + "\\n")

# minimal versions file
with open("versions.yml", "w") as vf:
    vf.write(f\"\"\"${task.process}:
  control_parser: 1.0
\"\"\")
EOF

    """
}
