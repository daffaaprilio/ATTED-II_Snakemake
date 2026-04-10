# ATTED-II v13 wrapper Snakefiles

This repository, mostly consists of Snakefile scripts, is designed to simplify the operation of ATTED-II plant gene co-expression database update.
The main scripts, i.e., the ones that 

- handle the gene expression data preparation and co-expression calculation
- being wrapped by scripts in this repository,

are kept and managed by the Information Biology Laboratory of Tohoku University.

# Usage
The scripts in this repository has been executed for the update of ATTED-II version 13.0. You can reproduce the result by following these steps below:

## Environment Preparation
```shell
# clone this repository
git clone

# install dependencies
conda install -n base -c conda-forge mamba -y
mamba install -n atted -c conda-forge -c bioconda snakemake 
```

## Data Preparation
First half of the calculation is to prepare the gene expression data.

### Reference Sequence Preparation
Make sure to check the config file `config/data_preparation.yaml` to:
- Set your working directory
- Include the species whose gene co-expression data is going to be calculated into the config file (link to download reference genome, annotation, species abbreviation, and taxonomy ID)
```shell
# Run the refseq snakefile script (after setting up the conda environment and installing Snakemake there)
snakemake -s 01_refseq_prep.smk -c 1
```

### Preparing Input Files for Coexpression Calculation
```shell
snakemake -s 02_data_prep.smk -c 1
```
Then, for each species, run this snakefile. It is important to run each snakefile individually, in order to not flood the system. Use as much cores when necessary (16 is optimal, out of 48 cores in cosmo)
```shell
# example for species_id='Hvu' and taxonomy_id=4513
snakemake -s 03_expression_data.smk -c 8 --config species_id='Hvu' taxonomy_id=4513 -np
```

### Coexpression calculation
Determine the calculation method: microarray (prefix: -m), RNA-seq (-r), union (-u) for each species. Consult the coexpression data table (https://atted.jp/download/) for the current list of species and each co-expression calculation prefix.
```shell
# RNA-based case: Hvu-r
snakemake -s 04_coex_calc_prep.smk --config species_id='Hvu' taxonomy_id=4513 -c 1
# Microarray case: Xxx-m
# since there are no microarray for the recent ATTED-II update, this is not implemented
# Union case: Xxx-u
snakemake -s 04_union_coex_calc_prep.smk --config species_id='Xxx' taxonomy_id=1111 -c 1
```
For each snakemake, this will create a species directory, i.e., `Ath-u/`, `Ath-r/`, `Sbi-r/`, etc. (*Arabidopsis thaliana* union, RNA-based, and *Sorghum bicolor* RNA-based gene co-expression calculation, respectively).
```shell
# go to species directory
cd Hvu-r/
# then, run the Snakefile inside
Snakemake -s run.smk
```

### Evaluation Data Preparation
```shell
snakemake -s 05_eval_prep.smk -c 1 -p
```
