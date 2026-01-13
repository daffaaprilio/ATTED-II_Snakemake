
WDIR = "/home/daffa/Work/2025/11-ATTED-II_ver-13.0"
SPECIES_ID = 'Ath'
TAXONOMY_ID = 3702

REP_NO = f"_{config.get('repetition_id', '')}" if config.get('repetition_id', '') else ""

'''
1. Create species directories exclusive to Ath: Ath-e, Ath-r, Ath-r_ecotype
2. In each species directory, create symbolic link to the output file
3. In Ath-r_ecotype, create ecotype batchrun script
'''
SPECIES_DIR = f"{WDIR}/{SPECIES_ID}-r_ecotype{REP_NO}" if REP_NO else f"{WDIR}/{SPECIES_ID}-r_ecotype"
SPECIES_CORE_DIR = f"{WDIR}/{SPECIES_ID}-r{REP_NO}" if REP_NO else f"{WDIR}/{SPECIES_ID}-r"
SPECIES_ECO_DIR = f"{WDIR}/{SPECIES_ID}-e{REP_NO}" if REP_NO else f"{WDIR}/{SPECIES_ID}-e"
OUTPUT_FILE = f"{WDIR}/output/{TAXONOMY_ID}"

rule all:
    input: 
        f"{SPECIES_CORE_DIR}/output",
        f"{SPECIES_ECO_DIR}/output",
        f"{SPECIES_DIR}/output",
        f"{SPECIES_DIR}/run.smk"

rule mkdir_spdir:
    output:
        SPECIES_DIR, SPECIES_CORE_DIR, SPECIES_ECO_DIR
    shell:
        '''
        mkdir -p {WDIR}/{SPECIES_DIR} {WDIR}/{SPECIES_ECO_DIR} {WDIR}/{SPECIES_CORE_DIR}
        '''
    
rule ln_output:
    output:
        core = directory(f"{SPECIES_CORE_DIR}/output"),
        eco = directory(f"{SPECIES_ECO_DIR}/output"),
        main = directory(f"{SPECIES_DIR}/output")
    shell:
        '''
        ln -s {OUTPUT_FILE} {output.core}
        ln -s {OUTPUT_FILE} {output.eco}
        ln -s {OUTPUT_FILE} {output.main}
        '''

rule coex_calc_script:
    params:
        template_file = f"{WDIR}/06_ath_coex_calc_template.smk",
        repetition_id = config.get('repetition_id', '')
    output:
        f"{SPECIES_DIR}/run.smk"
    shell:
        '''
        cp {params.template_file} {output}
        '''
