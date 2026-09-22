process ANCESTRY {
    tag "${id}"
    cpus 16
    container 'jamesrusssilsby/gnomadtools:latest'
    containerOptions "-B ${params.resourcesDir}/gnomad_pca -B ${params.batchDir} -B ${params.rsync}"
    // publishDir "${params.batchDir}/r04_metrics", mode: 'copy', overwrite: true, failOnError: true

    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(gvcf), file(csi)

    output:
      file("${id}.pca_scores.tsv")
      file("${id}.ancestry_assignment.tsv")

    script:
    """
    mkdir -p \$PWD/temp
    mkdir -p \$PWD/ivy_cache
    export TMPDIR=\$PWD/temp

    python3 <<EOF
import os
import hail as hl
import onnx

from hail.vds.combiner import transform_gvcf
from gnomad.sample_qc.ancestry import (
    apply_onnx_classification_model,
    assign_population_pcs,
)
from gnomad.utils.filtering import filter_to_adj
from gnomad.utils.sparse_mt import densify_all_reference_sites

# (Imports below were unused; keep if you plan to use later)
# from gnomad_qc.v2.resources.basics import get_gnomad_meta
# from gnomad_qc.v4.resources.basics import get_checkpoint_path

read_if_exists = True
v3_num_pcs = 16
v3_min_prob = 0.75

work = os.getcwd()
tmp_dir = f"{work}/temp"
ivy_dir = f"{work}/ivy_cache"

os.makedirs(tmp_dir, exist_ok=True)
os.makedirs(ivy_dir, exist_ok=True)
os.environ["TMPDIR"] = tmp_dir

hl.init(
    tmp_dir=tmp_dir,
    spark_conf={
        # Memory (tune to your container limits)
        "spark.driver.memory": "8g",
        "spark.executor.memory": "8g",

        # Keep Spark temp/local on our mounted tmp path
        "spark.local.dir": tmp_dir,

        # Correct Ivy cache location (for jar resolution)
        "spark.jars.ivy": ivy_dir,

        # Safer defaults for single-node runs
        "spark.driver.maxResultSize": "0",
        "spark.sql.shuffle.partitions": "64",
        "spark.ui.enabled": "false",
        "spark.eventLog.enabled": "false",
    },
)

hl.default_reference('GRCh38')

gnomad_v3_loadings = (
    "${params.resourcesDir}/gnomad_pca/gnomad.v3.1.pca_loadings.ht"
)

# v3.1 ONNX RF model (read via local FS, not Hadoop)
gnomad_v3_onnx_rf = (
    "${params.resourcesDir}/gnomad_pca/gnomad.v3.1.RF_fit.onnx"
)
with open(gnomad_v3_onnx_rf, "rb") as f:
    v3_onx_fit = onnx.load(f)

# Absolute output paths
# Use versioned checkpoint names so an old sparse-projection checkpoint cannot
# be silently reused after changing the densification logic.
mt_output_path          = os.path.join(work, "${id}_gnomad_v3.1_ancestry_rf.refsites_v1.mt")
scores_output_path      = os.path.join(work, "${id}_gnomad_v3.1_ancestry_rf.refsites_v1.scores.ht")
gnomad_assignment_path  = os.path.join(work, "${id}_gnomad_v3.1_ancestry_rf.refsites_v1.assignment.ht")

v3_loading_ht = hl.read_table(gnomad_v3_loadings)

mt = hl.import_vcf(
    "${gvcf}",
    reference_genome='GRCh38',
    array_elements_required=False,
    force_bgz=True
)

sample_vds = transform_gvcf(
    mt,
    reference_entry_fields_to_keep=["LA", "LGT", "GQ", "DP", "LAD"],
)

# Split multiallelic variant records into the biallelic representation used by
# the gnomAD PCA loading table. split_multi also converts reference-data LGT to
# GT, which is needed for densification.
sample_vds = hl.vds.split_multi(sample_vds, filter_changed_loci=True)

# Keep only variant rows that occur in the gnomAD PCA loading set. Importantly,
# hl.vds.filter_variants() does NOT remove the reference_data blocks, so the
# homozygous-reference information needed below is still available.
sample_vds = hl.vds.filter_variants(sample_vds, v3_loading_ht)

# CRITICAL: add every PCA loading site to the row set BEFORE densifying.
# A single-sample gVCF normally has no variant_data row at a 0/0 site; plain
# hl.vds.to_dense_mt(sample_vds) therefore omits those PCA sites altogether.
# densify_all_reference_sites() outer-joins the loading sites first and then
# uses the gVCF reference blocks to recover explicit 0/0 genotypes.
mt = densify_all_reference_sites(
    sample_vds,
    reference_ht=v3_loading_ht,
    row_key_fields=("locus", "alleles"),
    entry_keep_fields=("GT",),
)

# Projection QC: after correct densification the MT should have exactly one row
# for every loading-table row, and homozygous-reference calls should be common.
n_loadings = v3_loading_ht.count()
n_projection_rows = mt.count_rows()

gt_stats = mt.aggregate_entries(
    hl.struct(
        n_called=hl.agg.count_where(hl.is_defined(mt.GT)),
        n_missing=hl.agg.count_where(hl.is_missing(mt.GT)),
        n_hom_ref=hl.agg.count_where(
            hl.is_defined(mt.GT) & mt.GT.is_hom_ref()
        ),
        n_het=hl.agg.count_where(
            hl.is_defined(mt.GT) & mt.GT.is_het()
        ),
        n_hom_alt=hl.agg.count_where(
            hl.is_defined(mt.GT) & mt.GT.is_hom_var()
        ),
    )
)

print("========================================")
print("GNOMAD PCA PROJECTION QC")
print("========================================")
print(f"Loading variants : {n_loadings}")
print(f"Projection rows  : {n_projection_rows}")
print(f"Called           : {gt_stats.n_called}")
print(f"Missing          : {gt_stats.n_missing}")
print(f"Hom-ref          : {gt_stats.n_hom_ref}")
print(f"Het              : {gt_stats.n_het}")
print(f"Hom-alt          : {gt_stats.n_hom_alt}")
print(
    f"Call rate        : "
    f"{gt_stats.n_called / n_projection_rows:.4f}"
)
print("========================================")

if n_projection_rows != n_loadings:
    raise RuntimeError(
        f"PCA row mismatch: loading table has {n_loadings} rows "
        f"but projection MT has {n_projection_rows}"
    )

# Do not enable filter_to_adj here without also retaining GQ/DP/LAD in
# entry_keep_fields above. For PCA projection, the original gnomAD workflow
# commonly projects GT directly.
# mt = filter_to_adj(mt)

mt = mt.checkpoint(
    mt_output_path,
    overwrite=not read_if_exists,
    _read_if_exists=read_if_exists
)

v3_pcs_ht = hl.experimental.pc_project(
    mt.GT,
    v3_loading_ht.loadings,
    v3_loading_ht.pca_af,
)

v3_pcs_ht = v3_pcs_ht.checkpoint(
    scores_output_path,
    overwrite=not read_if_exists,
    _read_if_exists=read_if_exists,
)

ht, model = assign_population_pcs(
    v3_pcs_ht,
    pc_cols=v3_pcs_ht.scores[:v3_num_pcs],
    fit=v3_onx_fit,
    min_prob=v3_min_prob,
    apply_model_func=apply_onnx_classification_model,
)

ht = ht.checkpoint(
    gnomad_assignment_path,
    overwrite=not read_if_exists,
    _read_if_exists=read_if_exists,
)

v3_pcs_ht.export(
    "${id}.pca_scores.tsv",
    header=True,
    delimiter="\\t",
)

ht.export(
    "${id}.ancestry_assignment.tsv",
    header=True,
    delimiter="\\t",
)
EOF

DEST_DIR="${params.batchDir}/r04_metrics"
mkdir -p "\$DEST_DIR"

STAGE_DIR="\$DEST_DIR/.stage.${id}.\$\$"
rm -rf "\$STAGE_DIR"
mkdir -p "\$STAGE_DIR/.partial"

FILES=( "${id}.pca_scores.tsv" "${id}.ancestry_assignment.tsv" )

for f in "\${FILES[@]}"; do
  [[ -s "\$f" ]] || { echo "Missing/empty output: \$f" >&2; exit 1; }
done

attempts=5
delay=10
ok=0

for i in \$(seq 1 \$attempts); do
  # clean stage between attempts
  rm -f "\$STAGE_DIR/"* 2>/dev/null || true
  mkdir -p "\$STAGE_DIR/.partial"

  if ${params.rsync} -a --no-g --checksum --delay-updates \\
      --partial --partial-dir=".partial" \\
      "\${FILES[@]}" "\$STAGE_DIR/"; then
    ok=1
    break
  fi

  echo "rsync to stage failed (attempt \$i/\$attempts) — retrying in \${delay}s" >&2
  sleep "\$delay"
done

[[ "\$ok" -eq 1 ]] || { echo "Publish failed: rsync never succeeded" >&2; exit 1; }

for f in "\${FILES[@]}"; do
  [[ -s "\$STAGE_DIR/\$f" ]] || { echo "Stage missing/empty: \$STAGE_DIR/\$f" >&2; exit 1; }
done

# Promote data files
for f in "\${FILES[@]}"; do
  mv -f "\$STAGE_DIR/\$f" "\$DEST_DIR/\$f"
done

rm -rf "\$STAGE_DIR"


    """
}
