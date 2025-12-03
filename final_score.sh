#!/bin/bash

# Define the output directory
OUTPUT_DIR="output"
FUNCTION_SCORE_DIR="KEGG_FUNCTION_SCORE"

TAXID_LIST=(
    15368
    3708
    2711
    3055
    3635
    4097
    39946
    4558
    4113
)

SPID_LIST=(
    Bdi
    Bna
    Cit
    Cre
    Ghi
    Nta
    Osi
    Sbi
    Sot
)

# Generate the columns for the table by iterating through indices
TAXID=""
SPID=""
SRANO=""
COEXGENES=""
TESTGENES=""
KEGGSCORE=""

for i in "${!TAXID_LIST[@]}"; do
    taxid="${TAXID_LIST[$i]}"
    spid="${SPID_LIST[$i]}"
    
    # Get the values for each column
    TAXID="${TAXID}${taxid}\n"
    
    # Find the matching function score file for this species
    score_file=$(find "${FUNCTION_SCORE_DIR}" -name "*${spid}*" | head -1)
    if [[ -n "$score_file" && -f "$score_file" ]]; then
        SPID="${SPID}$(tail -1 "$score_file" | cut -f4)\n"
        COEXGENES="${COEXGENES}$(tail -1 "$score_file" | cut -f7)\n"
        TESTGENES="${TESTGENES}$(tail -1 "$score_file" | cut -f8)\n"
        KEGGSCORE="${KEGGSCORE}$(tail -1 "$score_file" | cut -f1)\n"
    else
        SPID="${SPID}${spid}\n"
        COEXGENES="${COEXGENES}N/A\n"
        TESTGENES="${TESTGENES}N/A\n"
        KEGGSCORE="${KEGGSCORE}N/A\n"
    fi
    
    # Count SRA files for this taxid
    sra_count=$(find "${OUTPUT_DIR}/${taxid}" -type f -size +0c 2>/dev/null | wc -l)
    SRANO="${SRANO}${sra_count}\n"
done
# Print a header for clarity
date
echo -e "TaxID\tSpecies ID\tNo. of SRAs\tNo. of coex. genes\t No. of used genes\tKEGG score"
paste <(echo -e "$TAXID") <(echo -e "$SPID") <(echo -e "$SRANO") <(echo -e "$COEXGENES") <(echo -e "$TESTGENES") <(echo -e "$KEGGSCORE") | column -t -s $'\t'