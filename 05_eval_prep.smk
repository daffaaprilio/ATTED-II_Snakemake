configfile: 'config/eval_preparation.yaml'

SPECIES_ID      = config['species_id']
TAXONOMY_ID     = config['taxonomy_id']
WDIR            = config['wdir']
GENES_KO_LIST_DOWNLOAD      = config['genes_ko_list_download']
GENES_PATHWAY_LIST_DOWNLOAD = config['genes_pathway_list_download']
GENES_ID_LIST_DOWNLOAD      = config['genes_id_download']
KEGG_FTP_PASS   = config['kegg_ftp_pass']
KEGG_FTP_USER   = config['kegg_ftp_user']
DATE_SUFFIX = config['date_suffix']

EVAL_DIR    = f"{WDIR}/Eval"
KEGGFULL    = f"{EVAL_DIR}/KEGG.{DATE_SUFFIX}/KEGGfull/{{species}}"
KEGG50      = f"{EVAL_DIR}/KEGG.{DATE_SUFFIX}/KEGG50/{{species}}"
PARALOGS    = f"{EVAL_DIR}/ko-genes.{DATE_SUFFIX}/{{species}}"

ALL_KEGGFULL    = expand(KEGGFULL, species=SPECIES_ID)
ALL_KEGG50      = expand(KEGG50, species=SPECIES_ID)
ALL_PARALOGS    = expand(PARALOGS, species=SPECIES_ID)

rule all:
    input:
        EVAL_DIR, ALL_KEGG50, ALL_PARALOGS

rule clean:
    shell:
        '''
        rm -rf {ALL_KEGGFULL} {ALL_KEGG50} {ALL_PARALOGS}
        '''

rule ftp_kegg:
    output: f"{EVAL_DIR}/data/genes_ko.list", f"{EVAL_DIR}/data/genes_ncbi-geneid.list", f"{EVAL_DIR}/data/genes_pathway.list"
    params:
        pathway_link = GENES_PATHWAY_LIST_DOWNLOAD,
        ko_link = GENES_KO_LIST_DOWNLOAD,
        id_link = GENES_ID_LIST_DOWNLOAD,
        user = KEGG_FTP_USER,
        passwd = KEGG_FTP_PASS
    shell:
        '''
        mkdir -p {EVAL_DIR}/data
        wget -nc --user {params.user} --password {params.passwd} {params.pathway_link} -O- | gzip -d > {EVAL_DIR}/data/genes_pathway.list
        wget -nc --user {params.user} --password {params.passwd} {params.ko_link} -O- | gzip -d > {EVAL_DIR}/data/genes_ko.list
        wget -nc --user {params.user} --password {params.passwd} {params.id_link} -O- | gzip -d > {EVAL_DIR}/data/genes_ncbi-geneid.list
        '''

rule kegg_full:
    input: 
        kegg_pathway = f"{EVAL_DIR}/data/genes_pathway.list", 
        gene_id = f"{EVAL_DIR}/data/genes_ncbi-geneid.list",         
        kegg_atted_conversion = f"{EVAL_DIR}/species"
    output: KEGGFULL
    shell:
        '''
        mkdir -p "$(dirname {output})"
        SPECIES=$(echo "{wildcards.species}" | tr '[:upper:]' '[:lower:]')
        
        CONVERSION_LINE=$(grep "^$SPECIES" {input.kegg_atted_conversion} || echo "$SPECIES")
        
        if [ $(echo "$CONVERSION_LINE" | wc -w) -gt 1 ]; then
            TARGET_SPECIES=$(echo "$CONVERSION_LINE" | awk '{{print $2}}')
        else
            TARGET_SPECIES="$SPECIES"
        fi
        
        awk -v sp="$TARGET_SPECIES" '
            BEGIN {{ FS = "[[:space:]]+" }}
            $1 ~ ("^" sp ":") && $2 ~ ("^path:" sp "[0-9]+") {{
                gene = $1; sub("^" sp ":", "", gene)
                path = $2; sub("^path:" sp, "", path)
                print gene, path
            }}
        ' {input.kegg_pathway} | sort -k2,2 > "{output}.2" 
        
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
        }}' "{output}.2" > "{output}"
        '''

rule kegg_50:
    input: KEGGFULL
    output: KEGG50
    shell:
        '''
        mkdir -p "$(dirname {output})"
        awk '
        {{
            gene_count = 0
            for(i=2; i<=NF; i++) {{
                if($i != "") gene_count++
            }}
            if(gene_count <= 50) print $0
        }}' {input} > {output}
        '''

rule ko_genes_all:
    input: 
        f"{EVAL_DIR}/data/genes_ko.list", 
        f"{EVAL_DIR}/data/genes_ncbi-geneid.list", 
        f"{EVAL_DIR}/species"
    params:
        wdir = WDIR,
        date = DATE_SUFFIX
    output: ALL_PARALOGS
    shell:
        '''
        mkdir -p {params.wdir}/Eval/ko-genes.{params.date}
        perl {params.wdir}/Eval/ko-genes.pl -w {params.wdir} -d {params.date}
        '''