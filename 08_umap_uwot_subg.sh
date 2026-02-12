#!/bin/zsh

log_file="../logs/08-umap_uwot_subg_`date '+%F'`.txt"
exec 2&1> >(tee -a ${log_file})

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
    Vvi-u
    Zma-u
)

# calc uwot for each subgroup nucl, mito, and chlo
for i in $SPS; do
    Rscript scripts/4-umap/x-51-uwot_coex.R -sp ${i}_nucl -nn 10 -dir "umap/atted.v130"
    Rscript scripts/4-umap/x-51-uwot_coex.R -sp ${i}_mito -nn 10 -dir "umap/atted.v130"
    Rscript scripts/4-umap/x-51-uwot_coex.R -sp ${i}_chlo -nn 10 -dir "umap/atted.v130"
done

Rscript scripts/4-umap/x-51-uwot_coex.R -sp Tae-r_nucl -nn 30 -dir "umap/atted.v130"
Rscript scripts/4-umap/x-51-uwot_coex.R -sp Tae-r_mito -nn 30 -dir "umap/atted.v130"
Rscript scripts/4-umap/x-51-uwot_coex.R -sp Tae-r_chlo -nn 30 -dir "umap/atted.v130"


