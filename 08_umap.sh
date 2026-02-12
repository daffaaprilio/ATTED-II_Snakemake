#!/bin/zsh

# wrap snakefiles of all species for umap preparation (subgroup thingy)

SPS=(
    Ath-u
    Bdi-r
    Bna-r
    Bra-r
    Cit-r
    Cre-r
    Ghi-r
    Gma-u
    Mtr-u
    Nta-r
    Osa-u
    Ppo-u
    Sbi-r
    Sly-u
    Sot-r
    # Tae-u
    Vvi-u
    Zma-u
)

printf '%s\n' "${SPS[@]}" | xargs -P 17 -I {} snakemake -c 1 -s 08_umap_prep.smk --config 'sp'={} --rerun-incomplete

# obtain raw uwot output (unedited umap data)
# for i in Ath-u Bra-r Gma-u Hvu-r Mtr-u Osa-u Ppo-u Sly-u Vvi-u Zma-u; do
#     Rscript scripts/4-umap/x-51-uwot_coex.R -sp ${i} -nn 10 -dir "umap/atted.v121"
# done