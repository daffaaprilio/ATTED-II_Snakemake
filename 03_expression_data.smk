import os

WDIR = "/home/daffa/Work/2025/11-ATTED-II_ver-13.0"
SPECIES_ID = config['species_id']
TAXONOMY_ID = config['taxonomy_id']
TAXONOMY_ID_LIST_FILE = f'{WDIR}/list/{TAXONOMY_ID}-list.txt'

# Parse the list file at the top level
ACC_IDS = []
URLS = []

if os.path.exists(TAXONOMY_ID_LIST_FILE):
    with open(TAXONOMY_ID_LIST_FILE, 'r') as f:
        for line in f:
            line = line.strip()
            if line:
                # full ftp link
                url = line
                # parse link 
                parts = line.split("/")
                sra_file = parts[-1]
                # accession id
                acc_id = sra_file.replace('.sra', '')
                # appending to each list
                ACC_IDS.append(acc_id)
                URLS.append(url)

# Create mapping from accession id to url
ACC_ID_TO_URL = {acc_id: url for acc_id, url in zip(ACC_IDS, URLS)}

rule all:
    input:
        expand(f"output/{TAXONOMY_ID}/{{acc_id}}.txt", acc_id = ACC_IDS)

rule main:
    output:
        f"output/{TAXONOMY_ID}/{{acc_id}}.txt"
    input:
        cmd = 'scripts/0-DataPreparation/2-RNA-seq/x-31-ftp-bowtie-featureCounts.sh'
    params:
        url = lambda wildcards: ACC_ID_TO_URL[wildcards.acc_id],
        taxonomy_id = TAXONOMY_ID,
        species_id = SPECIES_ID,
        wdir = WDIR
    threads: 2
    shell:
        '''
        zsh {input.cmd} {params.url} {params.taxonomy_id} {params.species_id} {params.wdir}
        '''

rule clean:
    shell:
        '''
        rm -rf tmp/ output/{TAXONOMY_ID}/ logs/{TAXONOMY_ID}/
        '''
