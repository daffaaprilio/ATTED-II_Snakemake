# ATTED-II v13 Snakemake wrapper

Snakemake orchestration for the ATTED-II gene co-expression update (v13). Calculation scripts live in [RNAseq-coexpression](https://github.com/informationbiology/RNAseq-coexpression) (Tohoku Univ. Information Biology Lab).

> **Original workflow** (notebook / `scripts/9-batchrun_shell/*.sh`, hardcoded paths): use [RNAseq-coexpression](https://github.com/informationbiology/RNAseq-coexpression) directly — this repo is optional.

## Setup

```shell
git clone https://github.com/daffaaprilio/ATTED-II_Snakemake.git ATTED-II_Snakemake
cd ATTED-II_Snakemake
git clone https://github.com/informationbiology/RNAseq-coexpression.git scripts

conda install -n base -c conda-forge mamba -y
mamba install -n atted -c conda-forge -c bioconda snakemake
```

### 1. `srainfo.sqlite3` (SRA metadata DB, not in repo)

- **Reuse (recommended):** ask your lab for a shared copy on `/mnt/hdd/...`.
- **Build (~5 days on DDBJ):** run [`p-01-qsub-create-database.sh`](https://github.com/informationbiology/RNAseq-coexpression/blob/main/0-DataPreparation/2-RNA-seq/p-01-qsub-create-database.sh) → [`x-01-create-database.py`](https://github.com/informationbiology/RNAseq-coexpression/blob/main/0-DataPreparation/2-RNA-seq/x-01-create-database.py).

### 2. `config/secrets.yaml` (git-ignored)

```shell
cp config/secrets.yaml.template config/secrets.yaml
```

Set `wdir` to your HDD work directory (use `/mnt/hdd/YOUR_USERNAME/ATTED-II_work`, not home):

```yaml
wdir: "/mnt/hdd/YOUR_USERNAME/ATTED-II_work"
```

`kegg_ftp_user` / `kegg_ftp_pass` are only needed for `05_eval_prep.smk` — edit in `secrets.yaml`.

### 3. Symlinks (one-time)

```shell
export WORK="/mnt/hdd/YOUR_USERNAME/ATTED-II_work"   # must match secrets.yaml wdir
export SRAINFO_DB="/mnt/hdd/.../srainfo.sqlite3"     # actual DB path (lab shared or your build)
bash scripts/setup_tool_symlinks.sh                  # optional
bash scripts/setup_workdir_symlinks.sh
```

`WORK` / `SRAINFO_DB` are only for the symlink script above. Snakemake reads `wdir` from `secrets.yaml` thereafter.

| Path | Role |
|------|------|
| `~/ATTED-II_Snakemake` | Snakefiles, `config/`, symlinks |
| `wdir` on `/mnt/hdd/` | `tmp/`, `refseq/`, `index/`, `output/`, `list/`, `logs/`, `Eval/`, `{Species}-r/` |

## Pipeline

Edit `config/data_preparation.yaml` (species, genome URLs) before Step 1.

Common flags: `-s` Snakefile, `-c` cores, `-n` dry run, `-p` print commands, `--keep-going` continue on failure. See [Snakemake docs](https://snakemake.readthedocs.io/en/stable/).

| Step | Snakefile | Notes |
|------|-----------|-------|
| 1 Ref genome & index | `01_refseq_prep.smk` | `-c 1` |
| 2 SRA lists & metadata | `02_data_prep.smk` | `-c 1` |
| 3 Expression counts | `03_expression_data.smk` | per species; `-c 12` recommended (2 CPUs/Bowtie job) |
| 5 Eval inputs | `05_eval_prep.smk` | before coexpression; needs KEGG creds in `secrets.yaml` |
| 4 Coex prep | `04_coex_calc_prep.smk` | RNA-seq (`-r`) |
| 4 Union prep | `04_union_coex_calc_prep.smk` | union (`-u`) |
| 6 Coex calc | `{Species}-r/run.smk` | generated under `wdir` |

```shell
# examples (species_id / taxonomy_id from data_preparation.yaml)
snakemake -s 01_refseq_prep.smk -c 1
snakemake -s 02_data_prep.smk -c 1
snakemake -s 05_eval_prep.smk -c 1 -p
snakemake -s 03_expression_data.smk -c 12 --config species_id='Hvu' taxonomy_id=4513 --keep-going
snakemake -s 04_coex_calc_prep.smk --config species_id='Hvu' taxonomy_id=4513 -c 1

cd /mnt/hdd/.../ATTED-II_work/Hvu-r
ulimit -s unlimited    # required before subagging (avoid segfault)
snakemake -s run.smk -c 1
```

Prefix guide: `-r` RNA-seq, `-u` union, `-m` microarray (not implemented in v13). See [atted.jp/download](https://atted.jp/download/).

**Wheat (`Tae-r`):** set `min_mean = 45` in the `combat_pca` rule of `06_coex_calc_template.smk` (params and shell `-l` flag).
