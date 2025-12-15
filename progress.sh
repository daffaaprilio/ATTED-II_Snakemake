#!/bin/bash

# Define the output directory
OUTPUT_DIR="output"

# Generate the columns for the table
COLUMN1=$(for taxid in ${OUTPUT_DIR}/*; do echo $taxid | sed -e 's|output/||'; done)
COLUMN2=$(for taxid in ${OUTPUT_DIR}/*; do ls $taxid | wc -l; done)
COLUMN3=$(for taxid in ${OUTPUT_DIR}/*; do find $taxid -type f -size +0c | wc -l; done)

# Print a header for clarity
date
echo -e "TaxID\tTotal Files\tNon-Empty Files"
paste <(echo "$COLUMN1") <(echo "$COLUMN2") <(echo "$COLUMN3") | column -t -s $'\t'