
WDIR = "/home/daffa/Work/2025/11-ATTED-II_ver-13.0"
LEGACY_DIR = "/home/hibara/ATTED-II_ver.11.0"
SPECIES_ID = config['species_id']
TAXONOMY_ID = config['taxonomy_id']

REP_NO = f"_{config.get('repetition_id', '')}" if config.get('repetition_id', '') else ""

'''
1. Create union species directory
2. In union species directory, create symbolic link to the nlmr.d directory of microarray data
3. In union species directory, create symbolic link to the nlmr.d directory of RNA-seq data
4. In union species directory, create batchrun script (from snakefile template)
'''

UNION_SPECIES_DIR = f"{WDIR}/{SPECIES_ID}-u{REP_NO}" if REP_NO else f"{WDIR}/{SPECIES_ID}-u"
SPECIES_DIR = f"{WDIR}/{SPECIES_ID}-r{REP_NO}" if REP_NO else f"{WDIR}/{SPECIES_ID}-r"
MICROARRAY_FILE = f"{LEGACY_DIR}/{SPECIES_ID}-m/nlmr.d"
RNASEQ_FILE = f"{SPECIES_DIR}/nlmr.d"

rule all:
    input:
        f"{UNION_SPECIES_DIR}/.{SPECIES_ID}-r.done",
        f"{UNION_SPECIES_DIR}/.{SPECIES_ID}-m.done",
        f"{UNION_SPECIES_DIR}/run.smk"

rule ln_microarray:
    output:
        temp(f"{UNION_SPECIES_DIR}/.{SPECIES_ID}-m.done")
    params:
        symlink_name = f"{UNION_SPECIES_DIR}/{SPECIES_ID}-m",
        microarray_file = MICROARRAY_FILE
    shell:
        '''
        mkdir -p {UNION_SPECIES_DIR}
        ln -sf {params.microarray_file} {params.symlink_name}
        touch {output}
        '''

rule ln_rnaseq:
    output:
        temp(f"{UNION_SPECIES_DIR}/.{SPECIES_ID}-r.done")
    params:
        symlink_name = f"{UNION_SPECIES_DIR}/{SPECIES_ID}-r",
        rnaseq_file = RNASEQ_FILE
    shell:
        '''
        mkdir -p {UNION_SPECIES_DIR}
        ln -sf {params.rnaseq_file} {params.symlink_name}
        touch {output}
        '''

rule union_script:
    params:
        template_file = f"{WDIR}/06_union_coex_calc_template.smk",
        repetition_id = config.get('repetition_id', '')
    output:
        f"{UNION_SPECIES_DIR}/run.smk"
    shell:
        '''
        mkdir -p {UNION_SPECIES_DIR}
        cp {params.template_file} {output}
        sed -i "s/config\\['species_id'\\]/'{SPECIES_ID}'/g" {output}
        sed -i "s/config\\['taxonomy_id'\\]/{TAXONOMY_ID}/g" {output}
        sed -i "s/config\\.get('repetition_id', '')/'{params.repetition_id}'/g" {output}
        '''