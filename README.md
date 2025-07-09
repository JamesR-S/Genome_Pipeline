# R04 Genome Pipeline

Author: **James Russ-Silsby** 

Email: **j.russ-silsby@exeter.ac.uk**

The R04 pipeline runs in nextflow and makes use of containers for many of the processing steps.

This guide will go through the set up for the pipeline and how to run it.

## Setting up the pipeline

### Installing Dependencies

The easiest way to install the dependencies is through micromamba. This can be installed with the following command:

```
"${SHELL}" <(curl -L micro.mamba.pm/install.sh)
```

Once micrimamba has been installed and loaded, create an environment with the required dependencies using the following command:

```
micromamba create \
	-n genome_sequencing \
	bioconda::nextflow=25.04.2 \
	conda-forge::apptainer=1.4.1
```

To activate the environment you then run `micromamba activate genome_sequencing`.

### Setting up environment

In addition to installing the dependencies you will also need to add the `APPTAINER_TMPDIR` variable to your environment. This is the directory to which temporary files that are part of the container download process will be saved. This can be added to the `.bashrc` file so that it gets loaded to the environment on start up as follows:

```
echo 'export APPTAINER_TMPDIR="/lustre/projects/Research_Project-MRC147594/genome_sequencing/NF_temp/"' \
>> ~/.bashrc
```

After this you will need to log out and back in again to the server or run `source ~/.bashrc` to restart your environment.

## Running the pipeline 

### Using tmux (optional, but highly recommended)

Because the pipeline takes 1-3 days to run (depending on batch size) it is highly recommended to run it within a `tmux` session. This means that if you get disconnected from the server the pipeline will continue to run and you can return to the terminal session it is running in at any time.

To do this first install tmux with `micromamba install tmux` then start a session with the command `tmux`. The session can be left at any time without killing the job by using the key combination `ctrl` + `b`, followed by `d` and rejoined at any time by running `tmux attach`. To kill the the session simply run `exit`. For more information on running tmux run `man tmux`.

### Setting up the control file

The pipeline will look for a `control` file with in the batch directory with sample information. These have already been created for all batches previously run using the R03 pipeline, but will need to be created for new batches. This file must contain a VERSION line with specifying that it is a genome batch, MALE and FEMALE lines containing the sexes of all samples in the batch, FAMILY lines for each family/singleton in the batch, TRIO lines for each trio and FASTQ lines for each fastq file pair in the batch. Here is an example:

```
VERSION genome

MALE WG1732 WG1735 WG1737 WG1739
FEMALE WG1733 WG1734 WG1736 WG1738 WG1744

FAMILY WG1732
FAMILY WG1733 WG1734 WG1735
TRIO WG1733 WG1735 WG1734
FAMILY WG1736 WG1737 WG1738 WG1739
TRIO WG1736 WG1737 WG1738
FAMILY WG1744

FASTQ WG1732 ILLUMINA E150011960L1C001R00300000129 WG1732_R1_1.fastq.gz WG1732_R2_1.fastq.gz
FASTQ WG1733 ILLUMINA E150012396L1C001R00300000091 WG1733_R1_1.fastq.gz WG1733_R2_1.fastq.gz
FASTQ WG1734 ILLUMINA E150012000L1C001R00100000130 WG1734_R1_1.fastq.gz WG1734_R2_1.fastq.gz
FASTQ WG1735 ILLUMINA E150012000L1C001R00100000152 WG1735_R1_1.fastq.gz WG1735_R2_1.fastq.gz
FASTQ WG1736 ILLUMINA E150012000L1C001R00100000129 WG1736_R1_1.fastq.gz WG1736_R2_1.fastq.gz
FASTQ WG1737 ILLUMINA E150012000L1C001R00100000132 WG1737_R1_1.fastq.gz WG1737_R2_1.fastq.gz
FASTQ WG1738 ILLUMINA E150012000L1C001R00100000182 WG1738_R1_1.fastq.gz WG1738_R2_1.fastq.gz
FASTQ WG1739 ILLUMINA E150011960L1C001R00300000149 WG1739_R1_1.fastq.gz WG1739_R2_1.fastq.gz
FASTQ WG1744 ILLUMINA E150012000L1C001R00100000138 WG1744_1_R1_1.fastq.gz WG1744_1_R2_1.fastq.gz
FASTQ WG1744 ILLUMINA E150025584L1C001R00100000152 WG1744_2_R1_1.fastq.gz WG1744_2_R2_1.fastq.gz
```

### Launching the pipeline

To begin load the conda environment with `micromamba activate genome_sequencing`.

Once this is done the pipeline can then be launched with the following srun command (replacing `<batch_directory>` with your actual batch directory):

```
srun -p mrcq -c 2 nextflow run \
	/lustre/projects/Research_Project-MRC147594/genome_sequencing/Genome_Pipeline/mainv2.nf \
	--batchDir <batch_directory> \
	-profile isca
```

If the pipeline fails for any reason it can also be resumed by running the above with the addition of the `-resume` flag.

As the pipeline runs it will write the outputs back to the batch directory within subdirectories with an `r04_` prefix.

Once the pipeline finishes successfully it will automatically run a cleanup step that clears the `work/` directory that contains all temporary files. However please always check that this runs correctly and manually wipe any remaining files if any are left behind.



