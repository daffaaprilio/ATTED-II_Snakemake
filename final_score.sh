#!/bin/bash

# Define the output directory
OUTPUT_DIR="output"
FUNCTION_SCORE_DIR="KEGG_FUNCTION_SCORE"

# Generate the columns for the table
TAXID=$(for taxid in ${OUTPUT_DIR}/* ; do echo $taxid | sed 's|output/||'; done) # taxid
SPID=$(for taxid in ${FUNCTION_SCORE_DIR}/*; do tail -1 "$taxid" | cut -f4; done)
SRANO=$(for taxid in ${OUTPUT_DIR}/* ; do find $taxid -type f -size +0c | wc -l; done) # no of SRAs (nonempty files in the {sp}/output/ directory)
COEXGENES=$(for taxid in ${FUNCTION_SCORE_DIR}/*; do tail -1 "$taxid" | cut -f7; done)
TESTGENES=$(for taxid in ${FUNCTION_SCORE_DIR}/*; do tail -1 "$taxid" | cut -f8; done)
KEGGSCORE=$(for taxid in ${FUNCTION_SCORE_DIR}/*; do tail -1 "$taxid" | cut -f1; done)
# Print a header for clarity
date
echo -e "TaxID\tSpecies ID\tNo. of SRAs\tNo. of coex. genes\t No. of used genes\tKEGG score"
paste <(echo "$TAXID") <(echo "$SPID") <(echo "$SRANO") <(echo "$COEXGENES") <(echo "$TESTGENES") <(echo "$KEGGSCORE") | column -t -s $'\t'