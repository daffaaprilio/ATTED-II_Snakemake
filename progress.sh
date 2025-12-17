#!/bin/bash

# Define the output directory
OUTPUT_DIR="output"

# Generate the columns for the table
COLUMN1=$(for taxid in ${OUTPUT_DIR}/*; do echo $taxid | sed -e 's|output/||'; done)
COLUMN2=$(for taxid in ${OUTPUT_DIR}/*; do 
    taxid_num=$(echo $taxid | sed 's|output/||')
    if [ -f "list/${taxid_num}-list.txt" ]; then
        wc -l < "list/${taxid_num}-list.txt"
    else
        echo "0"
    fi
done)
COLUMN3=$(for taxid in ${OUTPUT_DIR}/*; do ls $taxid 2>/dev/null | wc -l; done)
COLUMN4=$(for taxid in ${OUTPUT_DIR}/*; do find $taxid -type f -size +0c 2>/dev/null | wc -l; done)
COLUMN5=$(paste <(echo "$COLUMN2") <(echo "$COLUMN3") | awk '{print $1 - $2}')

# Print a header for clarity
date
echo -e "TaxID\tTotal SRAs\tTotal Output Files\tNon-Empty Output Files\tRemaining SRAs"
paste <(echo "$COLUMN1") <(echo "$COLUMN2") <(echo "$COLUMN3") <(echo "$COLUMN4") <(echo "$COLUMN5") | column -t -s $'\t'