#!/bin/zsh
log_file="logs/08-umap_v13_complete_`date '+%F'`.txt"
exec 2>&1 > >(tee -a ${log_file})

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
    # Tae-r (is excluded)
    Vvi-u
    Zma-u
)


# for SP in $SPS; do
#     # calc uwot
#     echo "UMAP pipeline for species ${SP}"
#     echo "Step (1) -> uwot calc whole coex data"
#     Rscript scripts/4-umap/x-51-uwot_coex.R -sp "${SP}" -nn 10 -dir "umap/atted.v130"
#     echo "         -> uwot calc for each subgroup"
#     Rscript scripts/4-umap/x-51-uwot_coex.R -sp "${SP}_nucl" -nn 10 -dir "umap/atted.v130"
#     Rscript scripts/4-umap/x-51-uwot_coex.R -sp "${SP}_mito" -nn 10 -dir "umap/atted.v130"
#     Rscript scripts/4-umap/x-51-uwot_coex.R -sp "${SP}_chlo" -nn 10 -dir "umap/atted.v130"
#     cd umap
#     # shrink
#     echo "Step (2) -> Shrink whole coex data"
#     Rscript ../scripts/4-umap/x-53-umap_shrink.R "${SP}"
#     echo "         -> Shrink for each subgroup"
#     Rscript ../scripts/4-umap/x-53-umap_shrink.R "${SP}_nucl"
#     Rscript ../scripts/4-umap/x-53-umap_shrink.R "${SP}_mito"
#     Rscript ../scripts/4-umap/x-53-umap_shrink.R "${SP}_chlo"
#     echo "Step (3) -> Rotate"
#     Rscript ../scripts/4-umap/x-54-rotation.R "${SP}"
#     cd ..
# done

# separate calculation for Tae-r
# calc uwot 
# 2026-02-09 19:40 ======== still troubleshooting ================
echo "UMAP pipeline for species Tae-r"
echo "Step (1) -> uwot calc whole coex data"
Rscript scripts/4-umap/x-51-uwot_coex.R -sp "Tae-r" -nn 30 -dir "umap/atted.v130"
echo "         -> uwot calc for each subgroup"
Rscript scripts/4-umap/x-51-uwot_coex.R -sp "Tae-r_nucl" -nn 30 -dir "umap/atted.v130"
Rscript scripts/4-umap/x-51-uwot_coex.R -sp "Tae-r_mito" -nn 30 -dir "umap/atted.v130"
Rscript scripts/4-umap/x-51-uwot_coex.R -sp "Tae-r_chlo" -nn 30 -dir "umap/atted.v130"
# cd umap
# # shrink
# echo "Step (2) -> Shrink whole coex data"
# Rscript ../scripts/4-umap/x-53-umap_shrink.R "Tae-r"
# echo "         -> Shrink for each subgroup"
# Rscript ../scripts/4-umap/x-53-umap_shrink.R "Tae-r_nucl"
# Rscript ../scripts/4-umap/x-53-umap_shrink.R "Tae-r_mito"
# Rscript ../scripts/4-umap/x-53-umap_shrink.R "Tae-r_chlo"
# echo "Step (3) -> Rotate"
# Rscript ../scripts/4-umap/x-54-rotation.R "Tae-r"
# cd ..