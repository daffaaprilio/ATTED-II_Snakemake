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
TAXID_LIST_FILE = f'{WDIR}/list/{{taxonomy_id}}-list.txt'
TAXID_PREFETCH_LIST_FILE = f'{WDIR}/list/{{taxonomy_id}}-prefetch_list.txt'
## lists creation (expanded across all target organisms)
ALL_LIST_FILES = expand(TAXID_LIST_FILE, taxonomy_id=TAXONOMY_ID)
ALL_PREFETCH_LIST_FILES = expand(TAXID_PREFETCH_LIST_FILE, taxonomy_id=TAXONOMY_ID)

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

#------------------------------------------------------------
# Rules

rule all:
    input:
        ALL_LIST_FILES,
        ALL_PREFETCH_LIST_FILES,
        STUDY_TABLE,
        STUDY_TITLE_NG_WORD,
        STUDY_ABSTRACT_NG_WORD

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
        TAXID_LIST_FILE,
        TAXID_PREFETCH_LIST_FILE

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
    shell: 'rm -rf {ALL_LIST_FILES} {ALL_PREFETCH_LIST_FILES} {STUDY_TABLE} {STUDY_TITLE_NG_WORD} {STUDY_ABSTRACT_NG_WORD} {BLACKLIST_STUDY} {BLACKLIST_RUN}'