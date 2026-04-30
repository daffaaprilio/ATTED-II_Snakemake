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
> About Snakemake Arguments <br>
[Snakemake](https://snakemake.readthedocs.io/en/stable/) is used to manage the workflow steps. Several arguments used quite often: <br>
`-n`: dry run <br>
`-s`: specify the Snakefile path to use <br>
`-p`: print the shell commands that will be executed for each rule <br>
`-c`: number of CPU cores <br>
`-j`: number of concurrent jobs <br>

### Evaluation Data Preparation
```shell
snakemake -s 05_eval_prep.smk -c 1 -p
```
This is to prepare all scripts/input files specific for the evaluation steps. Please do this before proceeding to the coexpression calculation. Since the coexpression calculation script wraps all steps (including the evaluation) together.

### Preparing Input Files for Coexpression Calculation
```shell
snakemake -s 02_data_prep.smk -c 1
```
Then, for each species, run this snakefile. It is important to run each snakefile individually, in order to not flood the system. Use as much cores when necessary (12 is optimal, out of 48 cores in cosmo, be advised that a Bowtie job requires 2 CPU).
```shell
# example for species_id='Hvu' and taxonomy_id=4513
snakemake -s 03_expression_data.smk -c 12 --config species_id='Hvu' taxonomy_id=4513 -np --keep-going
```
> About `--keep-going` argument <br>
With `--keep-going` flag, Snakemake will continue scheduling the remaining jobs even when individual ones fail.

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
#### Special cases
Additional parameters for wheat (`Tae-r`):
```python
rule combat_pca:
    params:
        pca = PCA_TYPE
        min_mean = 45 # change filtering option for wheat
    input:
        f"{WDIR}/refseq/{cutSP}-r_SpeciesSpecific2EGI",
        f"{WDIR}/blacklist-run",
        f"{WDIR}/srainfo-study_table.txt"
    output:
        f"{SPECIES_DIR}/list.txt",
        f"{SPECIES_DIR}/key",
        f"{SPECIES_DIR}/gc.d/1.gc",
        f"{SPECIES_DIR}/paste.expression.combat",
        f"{SPECIES_DIR}/pca_loadings.txt"
    log:
        f"{SPECIES_DIR}/logs/combat_pca.{LOG_DATETIME}.log"
    shell: # apply the change here as well
        '''
        cd {WDIR}
        Rscript {WDIR}/scripts/2-Subsampling/x-43-ComBat.RNA-seq.SGI2EGI.R -s {SP} -p {params.pca} -l {params.min_mean} > {log} 2>&1
        '''
```
For each snakemake, this will create a species directory, i.e., `Ath-u/`, `Ath-r/`, `Sbi-r/`, etc. (*Arabidopsis thaliana* union, RNA-based, and *Sorghum bicolor* RNA-based gene co-expression calculation, respectively).
```shell
# go to species directory
cd Hvu-r/
# then, run the Snakefile inside
snakemake -s run.smk -n -c 1
```
> Note when running coexpression calculation <br>
> Before running the `subagging_coexpression` rule, make sure to set `ulimit -s unlimited` on the terminal. <br>
> If you run it on a separate screen session, then set `ulimit -s unlimited` on that screen, before running the snakemake. This is to prevent segmentation fault when running the coexpression calculation script (`79m_logit_mrgeo.Xxx-x.vDD-MM.P12345-S123.combat_pca.subagging`)
