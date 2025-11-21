process ANCESTRY {
    tag "${id}"
    cpus 16
    container 'jamesrusssilsby/gnomadtools:latest'
    containerOptions "-B ${params.resourcesDir}/gnomad_pca"
    publishDir "${params.batchDir}/r04_metrics", mode: 'copy'

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
mt_output_path          = os.path.join(work, "${id}_gnomad_v3.1_ancestry_rf.mt")
scores_output_path      = os.path.join(work, "${id}_gnomad_v3.1_ancestry_rf.scores.ht")
gnomad_assignment_path  = os.path.join(work, "${id}_gnomad_v3.1_ancestry_rf.assignment.ht")

v3_loading_ht = hl.read_table(gnomad_v3_loadings)

mt = hl.import_vcf(
    "${gvcf}",
    reference_genome='GRCh38',
    array_elements_required=False,
    force_bgz=True
)

sample_vds = transform_gvcf(mt, reference_entry_fields_to_keep=["LA", "LGT", "GQ", "DP", "LAD"])
sample_vds = hl.vds.split_multi(sample_vds, filter_changed_loci=True)
sample_vds = hl.vds.filter_variants(sample_vds, v3_loading_ht)
mt = hl.vds.to_dense_mt(sample_vds)
# mt = filter_to_adj(mt)  # Enable if you want adj filtering

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
    """
}
