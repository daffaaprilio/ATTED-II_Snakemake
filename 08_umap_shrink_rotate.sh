#!/bin/zsh

log_file="../logs/08-umap_shrink_rotate_`date '+%F'`.txt"
exec 2&1> >(tee -a ${log_file})

# shrink-rotate
cd umap/
date

echo "(1) Shrink..."
for SP in Ath-u.nn10 Bdi-r.nn10 Bna-r.nn10 Bra-r.nn10 Cit-r.nn10 Cre-r.nn10 Ghi-r.nn10 Gma-u.nn10 Mtr-u.nn10 Nta-r.nn10 Osa-u.nn10 Ppo-u.nn10 Sbi-r.nn10 Sly-u.nn10 Sot-r.nn10 Vvi-u.nn10 Zma-u.nn10; do
  # Rスクリプトを呼び出す前に、SP変数から .nn10 を取り除く
  local SP_BASE=${SP%.nn10} 
  echo "   -> Processing: ${SP_BASE}"
  Rscript ../scripts/4-umap/x-53-umap_shrink.R "${SP_BASE}" # 拡張子なしの名前を渡す
done

echo "(2) Rotation..."
for i in $SPS; do
    Rscript ../scripts/4-umap/x-54-rotation.R ${i}
done

date
echo "Finished."

#==========
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

echo "(1a) Shrink whole data (non-subgroup)..."
for SP in $SPS; do
    echo "   -> Processing: ${SP}"
    Rscript ../scripts/4-umap/x-53-umap_shrink.R "${SP}"
done

echo "(1b) Shrink subgroup data ..."
for SP in $SPS; do
    echo "   -> Processing: ${SP} subgroups"
    Rscript ../scripts/4-umap/x-53-umap_shrink.R "${SP}_nucl"
    Rscript ../scripts/4-umap/x-53-umap_shrink.R "${SP}_mito"
    Rscript ../scripts/4-umap/x-53-umap_shrink.R "${SP}_chlo"
done

echo "(2) Rotation ..."
for SP in $SPS; do
    Rscript ../scripts/4-umap/x-54-rotation.R "${SP}"
done
