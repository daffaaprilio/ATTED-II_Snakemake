#!/bin/bash

species_ids=(Bdi Bra Cit Cre Osa Osi Sbi Sot)
taxonomy_ids=(15368 3711 2711 3055 39947 39946 4558 4113)

for i in "${!species_ids[@]}"; do
    sp="${species_ids[$i]}"
    tax="${taxonomy_ids[$i]}"
    
    echo "Submitting $sp (taxonomy: $tax)..."
    snakemake -s 04_coex_calc_prep.smk --config species_id="$sp" taxonomy_id="$tax" -c1 &
done

wait
echo "All species completed!"