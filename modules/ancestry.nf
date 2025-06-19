rocess ANCESTRY {
    tag "${id}"
    cpus 16
    container 'jamesrusssilsby/gnomadtools:latest'
    containerOptions{"-B ${params.resourcesDir}/gnomad_pca"}
    publishDir "${params.batchDir}/r04_metrics", mode: 'copy'
    input:
      tuple val(id), val(sex), val(family), val(famSampleCount), file(gvcf), file(csi)

    output:
      file("${id}.pca_scores.tsv")
      file("${id}.ancestry_assignment.tsv")

    script:
    """
    mkdir \$PWD/temp
    python3 <<EOF
import onnx
import hail as hl
from hail.vds.combiner import transform_gvcf
from gnomad.sample_qc.ancestry import (
    apply_onnx_classification_model,
    assign_population_pcs,
)
from gnomad.utils.filtering import filter_to_adj

from gnomad_qc.v2.resources.basics import get_gnomad_meta
from gnomad_qc.v4.resources.basics import get_checkpoint_path

read_if_exists = True
v3_num_pcs = 16
v3_min_prob = 0.75

hl.init(default_reference='GRCh38',
    tmp_dir="\$PWD/temp", 
    spark_conf={
        "spark.driver.extraJavaOptions"  : f"-Djava.io.tmpdir=\$PWD/temp",
        "spark.executor.extraJavaOptions": f"-Djava.io.tmpdir=\$PWD/temp",
        "spark.local.dir" : "\$PWD/temp",
    })

gnomad_v3_loadings = (
    "${params.resourcesDir}/gnomad_pca/gnomad.v3.1.pca_loadings.ht"
)

# v3.1 ONNX RF model.
gnomad_v3_onnx_rf = (
    "${params.resourcesDir}/gnomad_pca/gnomad.v3.1.RF_fit.onnx"
)

with hl.hadoop_open(gnomad_v3_onnx_rf, "rb") as f:
    v3_onx_fit = onnx.load(f)

mt_output_path        = f"${id}_gnomad_v3.1_ancestry_rf.mt"
scores_output_path    = f"${id}_gnomad_v3.1_ancestry_rf.scores.ht"
gnomad_assignment_path = f"${id}_gnomad_v3.1_ancestry_rf.assignment.ht"

v3_loading_ht = hl.read_table(gnomad_v3_loadings)

mt = hl.import_vcf("${gvcf}", reference_genome='GRCh38', array_elements_required=False, force_bgz=True)
sample_vds = transform_gvcf(mt, reference_entry_fields_to_keep=["LA", "LGT", "GQ", "DP", "LAD"])
sample_vds = hl.vds.split_multi(sample_vds, filter_changed_loci=True)
sample_vds = hl.vds.filter_variants(sample_vds, v3_loading_ht)
mt = hl.vds.to_dense_mt(sample_vds)
# mt = filter_to_adj(mt)

mt = mt.checkpoint(
    mt_output_path, overwrite=not read_if_exists, _read_if_exists=read_if_exists
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
    f"${id}.pca_scores.tsv",   
    header=True,                      
    delimiter="\t",                   
)

ht.export(
    f"${id}.ancestry_assignment.tsv",
    header=True,
    delimiter="\t",
)

EOF
    """
}
