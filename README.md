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
