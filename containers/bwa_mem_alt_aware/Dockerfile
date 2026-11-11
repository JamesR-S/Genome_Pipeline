# Image for BWA_MEM: bwa-mem2, bwa (fallback), samtools and bwa-postalt.js
# bwa-postalt.js doesn't work with k8 1.x, so the k8 0.2.5 release binary is used
#
#   sha256sum -c containers/bwa_mem_alt_aware/SHA256SUMS
#   docker build -t jamescraufurd/bwa_mem_alt_aware:1.0 containers/bwa_mem_alt_aware
#   docker push jamescraufurd/bwa_mem_alt_aware:1.0
# bwa_mem_alt_aware.def builds the same image with apptainer

FROM mambaorg/micromamba:1.5.10

USER root
# procps for nextflow's task metrics, zlib/libstdc++ for k8
RUN apt-get update \
 && apt-get install -y --no-install-recommends procps bzip2 zlib1g libstdc++6 \
 && rm -rf /var/lib/apt/lists/*

RUN micromamba install -y -n base -c conda-forge -c bioconda \
      bwa-mem2=2.2.1 bwa=0.7.19 samtools=1.21 \
 && micromamba clean -a -y

# k8 release binary (the bioconda k8 0.2.5 clashes with bwa over zlib)
COPY k8-0.2.5.tar.bz2 /opt/
RUN tar --no-same-owner -xjf /opt/k8-0.2.5.tar.bz2 -C /opt k8-0.2.5/k8-Linux \
 && install -m 755 /opt/k8-0.2.5/k8-Linux /usr/local/bin/k8 \
 && rm -rf /opt/k8-0.2.5 /opt/k8-0.2.5.tar.bz2

# bwa-postalt.js from bwa v0.7.19
COPY bwa-postalt.js /opt/bwakit/bwa-postalt.js
RUN chmod 644 /opt/bwakit/bwa-postalt.js

# apptainer doesn't run the micromamba entrypoint
ENV PATH=/opt/conda/bin:$PATH

# check the tools run
RUN command -v ps > /dev/null \
 && k8 /opt/bwakit/bwa-postalt.js -v | grep -qx r985 \
 && bwa-mem2 version 2>&1 | grep -q '^2\.2\.1' \
 && bwa 2>&1 | grep -q 'Version: 0\.7\.19' \
 && samtools --version | grep -q '^samtools 1\.21'

USER $MAMBA_USER
