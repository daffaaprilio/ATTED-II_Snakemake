#!/bin/bash

species_ids=(Sbi Cre Sot Osi Cit Bdi Nta Bra Mtr Osa Ppo Sly Zma)
taxonomy_ids=(4558 3055 4113 39946 2711 15368 4097 3711 3880 39947 3694 4081 4577)

for i in "${!species_ids[@]}"; do
    sp="${species_ids[$i]}"
    tax="${taxonomy_ids[$i]}"
    
    echo "Submitting $sp (taxonomy: $tax)..."
    snakemake -s 04_coex_calc_prep.smk --config species_id="$sp" taxonomy_id="$tax" -c1 &
done

wait
echo "All species completed!"