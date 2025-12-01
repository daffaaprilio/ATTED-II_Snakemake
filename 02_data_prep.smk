#------------------------------------------------------------
# load the configuration
import os
configfile: '02_data_prep.yaml'
SPECIES_ID = config['species_id']
TAXONOMY_ID = config['taxonomy_id']
NG_WORDS = config['NG_words']
WDIR = config['wdir']

#------------------------------------------------------------
# STEP 1: assigning working directory & database path
METADATADB = f'{WDIR}/srainfo.sqlite3'

# STEP 2: list creation (single species)
TAXID_LIST = f'{WDIR}/list/{{taxonomy_id}}-list.txt'
TAXID_PREFETCH_LIST = f'{WDIR}/list/{{taxonomy_id}}-prefetch_list.txt'
## lists creation (expanded across all target organisms)
ALL_LIST = expand(TAXID_LIST, taxonomy_id=TAXONOMY_ID)
ALL_PREFETCH_LIST = expand(TAXID_PREFETCH_LIST, taxonomy_id=TAXONOMY_ID)

# STEP 3: study table
STUDY_TABLE = f'{WDIR}/srainfo-study_table.txt'

# STEP 4: NG words
STUDY_TITLE_NG_WORD = f'{WDIR}/study-title-NG_word.txt'
STUDY_ABSTRACT_NG_WORD = f'{WDIR}/study-abstract-NG_word.txt'

# STEP 5: blacklist
BLACKLIST_STUDY = f'{WDIR}/blacklist-study'
BLACKLIST_RUN = f'{WDIR}/blacklist-run'

#------------------------------------------------------------
# miscellaneous
## dict for SPID-TAXID conversion
SPECIES_TO_TAXID = dict(zip(SPECIES_ID, TAXONOMY_ID))
TAXID_TO_SPECIES = dict(zip(TAXONOMY_ID, SPECIES_ID))

## special input parameters for all taxonomy ids concatenated
ALL_TAXONOMY_IDS = ""
for taxid in TAXONOMY_ID:
    taxid = str(taxid)    
    ALL_TAXONOMY_IDS += taxid + ","
ALL_TAXONOMY_IDS = ALL_TAXONOMY_IDS[0:-1]

## helper function to get accessions for a specific taxonomy_id
def get_accessions_for_taxid(taxonomy_id):
    list_file = f'{WDIR}/list/{taxonomy_id}-list.txt'
    if os.path.exists(list_file):
        with open(list_file, 'r') as f:
            urls = [line.strip() for line in f if line.strip()]
        return [os.path.basename(url).replace('.sra', '') for url in urls]
    return []

## helper function to get URL for a specific accession
def get_url_for_accession(taxonomy_id, accession):
    list_file = f'{WDIR}/list/{taxonomy_id}-list.txt'
    if os.path.exists(list_file):
        with open(list_file, 'r') as f:
            urls = [line.strip() for line in f if line.strip()]
        for url in urls:
            if accession in url:
                return url
    return ""

## helper function to list all accession for one taxid
def get_all_accession_files():
    all_files = []
    for taxonomy_id in TAXONOMY_ID:
        accessions = get_accessions_for_taxid(taxonomy_id)
        for accession in accessions:
            all_files.append(f'{WDIR}/output/{taxonomy_id}/{accession}.txt')
    return all_files


#------------------------------------------------------------
# Rules

rule part_one:
    input:
        ALL_LIST,
        ALL_PREFETCH_LIST,
        STUDY_TABLE,
        STUDY_TITLE_NG_WORD,
        STUDY_ABSTRACT_NG_WORD

rule part_two:
    input:
        BLACKLIST_RUN

rule part_three:
    input: 
        get_all_accession_files()
        
# Generic rule for processing one accession
rule expression_data_generation:
    input:
        cmd = 'scripts/0-DataPreparation/2-RNA-seq/x-31-ftp-bowtie-featureCounts.sh',
        index = lambda wildcards: expand(f'{WDIR}/index/{{taxonomy_id}}.{{ext}}.bt2', ext=['1','2','3','4','rev.1','rev.2'], taxonomy_id=wildcards.taxonomy_id),
        annotation = lambda wildcards: f'{WDIR}/refseq/{TAXID_TO_SPECIES[int(wildcards.taxonomy_id)]}_annotation'
    params:
        wdir = WDIR,
        species = lambda wildcards: TAXID_TO_SPECIES[int(wildcards.taxonomy_id)],
        url = lambda wildcards: get_url_for_accession(wildcards.taxonomy_id, wildcards.accession)
    output:
        f'{WDIR}/output/{{taxonomy_id}}/{{accession}}.txt'
    threads: 1
    shell:
        '''
        zsh {input.cmd} {params.url} {wildcards.taxonomy_id} {params.species} {params.wdir} {threads}
        '''

rule create_list:
    input:
        cmd = 'scripts/0-DataPreparation/2-RNA-seq/x-02-create_run_accession_path_list.py',
        metadataDB = METADATADB
    params:
        wdir = WDIR,
        max_run_in_study = 100000,
        min_run_in_study = 10,
        shuffle = True,
        run_list = True,
        ftp_ddbj = True
        
    output:
        TAXID_LIST,
        TAXID_PREFETCH_LIST

    shell:
        'python3 {input.cmd} --taxonomy-id {wildcards.taxonomy_id} --database {input.metadataDB} --output {params.wdir} --max-run-in-study {params.max_run_in_study} --min-run-in-study {params.min_run_in_study}'
        + (' --shuffle' if params.shuffle else '')
        + (' --run-list' if params.run_list else '')
        + (' --ftp-ddbj' if params.ftp_ddbj else '')

rule create_study_table:
    input: 
        cmd = 'scripts/0-DataPreparation/2-RNA-seq/x-03-create-srainfo-study.py',
        metadataDB = METADATADB
    params:
        wdir = WDIR,
        taxids = ALL_TAXONOMY_IDS
    
    output:
        STUDY_TABLE
    
    shell:
        'python3 {input.cmd} --database {input.metadataDB} --output-dir {params.wdir} --taxids {params.taxids}'

rule check_NG_words:
    input:
        cmd = 'scripts/0-DataPreparation/2-RNA-seq/x-04-check-NG_word.py',
        metadataDB = METADATADB
    params:
        wdir = WDIR,
        taxids = ALL_TAXONOMY_IDS,
        ng_words = " ".join(f'"{word}"' for word in NG_WORDS)
    output:
        STUDY_TITLE_NG_WORD,
        STUDY_ABSTRACT_NG_WORD
    
    shell: 
        'python3 {input.cmd} --NG_word {params.ng_words} --db {input.metadataDB} --output {params.wdir} --taxids {params.taxids}'

rule blacklist_run:
    input:
        cmd = 'scripts/0-DataPreparation/2-RNA-seq/x-05-create-blacklist-run.py',
        blacklist_study = BLACKLIST_STUDY,
        study_table = STUDY_TABLE
    params:
        wdir = WDIR,

    output:
        BLACKLIST_RUN

    shell:
        'python3 {input.cmd} --blacklist-study {input.blacklist_study} --study-table-path {input.study_table} --output-dir {params.wdir}'
        
rule clean:
    shell: 'rm -rf {ALL_LIST} {ALL_PREFETCH_LIST} {STUDY_TABLE} {STUDY_TITLE_NG_WORD} {STUDY_ABSTRACT_NG_WORD} {BLACKLIST_STUDY} {BLACKLIST_RUN}'