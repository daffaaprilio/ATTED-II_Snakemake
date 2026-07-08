import os

configfile: 'config/data_preparation.yaml'
configfile: 'config/secrets.yaml'

def _config_scalar(name, value):
    if isinstance(value, list):
        if len(value) != 1:
            raise ValueError(
                f"Step 03 requires a single {name}. "
                f"Pass --config {name}=<value> (got list of {len(value)})."
            )
        return value[0]
    return value

WDIR = config['wdir']
SPECIES_ID = _config_scalar('species_id', config['species_id'])
TAXONOMY_ID = _config_scalar('taxonomy_id', config['taxonomy_id'])
TAXONOMY_ID_LIST_FILE = f'{WDIR}/list/{TAXONOMY_ID}-list.txt'
INDEX_MARKER = f'{WDIR}/index/{TAXONOMY_ID}.done'
REFSEQ_EGI = f'{WDIR}/refseq/{SPECIES_ID}-r_SpeciesSpecific2EGI'
REFSEQ_ANNOTATION = f'{WDIR}/refseq/{SPECIES_ID}_annotation'

EXPRESSION_MAX_RUNS = config.get('expression_max_runs', {})
MAX_RUNS = int(
    config.get('max_runs', 0)
    or EXPRESSION_MAX_RUNS.get(str(TAXONOMY_ID), 0)
    or 0
)

# Parse the list file at the top level
ACC_IDS = []
URLS = []

if os.path.exists(TAXONOMY_ID_LIST_FILE):
    with open(TAXONOMY_ID_LIST_FILE, 'r') as f:
        for line in f:
            line = line.strip()
            if line:
                url = line
                acc_id = line.split("/")[-1].replace('.sra', '')
                ACC_IDS.append(acc_id)
                URLS.append(url)

if MAX_RUNS > 0:
    ACC_IDS = ACC_IDS[:MAX_RUNS]
    URLS = URLS[:MAX_RUNS]

ACC_ID_TO_URL = {acc_id: url for acc_id, url in zip(ACC_IDS, URLS)}

rule all:
    input:
        expand(f"{WDIR}/output/{TAXONOMY_ID}/{{acc_id}}.txt", acc_id=ACC_IDS)

rule main:
    input:
        cmd='scripts/0-DataPreparation/2-RNA-seq/x-31-ftp-bowtie-featureCounts.sh',
        index=INDEX_MARKER,
        annotation=REFSEQ_ANNOTATION,
        egi=REFSEQ_EGI,
    output:
        f"{WDIR}/output/{TAXONOMY_ID}/{{acc_id}}.txt"
    params:
        url=lambda wildcards: ACC_ID_TO_URL[wildcards.acc_id],
        taxonomy_id=TAXONOMY_ID,
        species_id=SPECIES_ID,
        wdir=WDIR
    log:
        f"{WDIR}/logs/{TAXONOMY_ID}/{{acc_id}}_snakemake.log"
    threads: 2
    resources:
        mem_mb=8000
    shell:
        '''
        set -euo pipefail
        zsh {input.cmd} {params.url} {params.taxonomy_id} {params.species_id} {params.wdir}
        '''

rule clean:
    shell:
        '''
        rm -rf {WDIR}/tmp/ {WDIR}/output/{TAXONOMY_ID}/ {WDIR}/logs/{TAXONOMY_ID}/
        '''
