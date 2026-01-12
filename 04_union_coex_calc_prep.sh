#!/bin/bash

species_ids=(Ppo Sly Vvi Zma)
taxonomy_ids=(3694 4081 29760 4577)

for i in "${!species_ids[@]}"; do
    sp="${species_ids[$i]}"
    tax="${taxonomy_ids[$i]}"
    
    echo "Submitting $sp (taxonomy: $tax)..."
    snakemake -s 04_union_coex_calc_prep.smk --config species_id="$sp" taxonomy_id="$tax" -c1 &
done

wait
echo "All species completed!"