#!/bin/bash
WDIR=/home/daffa/Work/2025/11-ATTED-II_ver-13.0

# to update kegg_full rule in the eval prep smk for Cre
kegg_pathway=${WDIR}/Eval/data/genes_pathway.list
gene_id=${WDIR}/refseq/Cre-r_SpeciesSpecific2EGI       
kegg_atted_conversion=${WDIR}/Eval/species
output=${WDIR}/testing_cre_full/Cre
actual_output=${WDIR}/testing_cre_50/Cre

SPECIES=$(echo "Cre" | tr '[:upper:]' '[:lower:]')

CONVERSION_LINE=$(grep "^$SPECIES" ${kegg_atted_conversion} || echo "$SPECIES")

if [ $(echo "$CONVERSION_LINE" | wc -w) -gt 1 ]; then
    TARGET_SPECIES=$(echo "$CONVERSION_LINE" | awk '{{print $2}}')
else
    TARGET_SPECIES="$SPECIES"
fi

# list kegg pathway genes
awk -v sp="$TARGET_SPECIES" '
    BEGIN {{ FS = "[[:space:]]+" }}
    $1 ~ ("^" sp ":") && $2 ~ ("^path:" sp "[0-9]+") {{
        gene = $1; sub("^" sp ":", "", gene)
        path = $2; sub("^path:" sp, "", path)
        print gene, path
    }}
' "$kegg_pathway" | sort -k2,2 > "$output.2.pre"

# change from species-specific id to EGI
awk '
    BEGIN {
    while ((getline line < "'$gene_id'") > 0) {
        split(line, parts, "\t")
        conv[parts[1]] = parts[2]
    }
}
{
    line = $0
    for (old in conv) {
        gsub(old, conv[old], line)
    }
    print line
}' "$output.2.pre" > "$output.2" 

# change the format to pathway: genes
awk '
{{
    if ($2 == prev_pathway) {{
        genes = genes "\t" $1
    }} else {{
        if (NR > 1) print prev_pathway genes
        prev_pathway = $2
        genes = "\t" $1
    }}
}}
END {{
    if (NR > 0) print prev_pathway genes
}}' "$output.2" > "$output"

# filter to KEGG50
awk '
{{
    gene_count = 0
    for(i=2; i<=NF; i++) {{
        if($i != "") gene_count++
    }}
    if(gene_count <= 50) print $0
}}' "$output" > "$actual_output"