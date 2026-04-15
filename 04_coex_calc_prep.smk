
WDIR = config['wdir']
SPECIES_ID = config['species_id']
TAXONOMY_ID = config['taxonomy_id']

REP_NO = f"_{config.get('repetition_id', '')}" if config.get('repetition_id', '') else ""

'''
1. Create species directory
2. In species directory, create symbolic link to the output file
3. In species directory, create batchrun script (from snakefile template)
'''

SPECIES_DIR = f"{WDIR}/{SPECIES_ID}-r{REP_NO}" if REP_NO else f"{WDIR}/{SPECIES_ID}-r"
OUTPUT_FILE = f"{WDIR}/output/{TAXONOMY_ID}"

rule all:
    input: 
        f"{SPECIES_DIR}/output",
        f"{SPECIES_DIR}/run.smk"

rule mkdir_spdir:
    output:
        SPECIES_DIR
    params:
        wdir = WDIR,
        dirname = SPECIES_DIR
    shell:
        '''
        mkdir -p {params.wdir}/{params.dirname}
        '''

rule ln_output:
    params:
        output_file = OUTPUT_FILE,
        symlink_name = f"{SPECIES_DIR}/output"
    output:
        directory(f"{SPECIES_DIR}/output")
    shell:
        '''
        ln -s {params.output_file} {params.symlink_name}
        '''

rule coex_calc_script:
    params:
        template_file = f"{WDIR}/06_coex_calc_template.smk",
        species_id = SPECIES_ID,
        taxonomy_id = TAXONOMY_ID,
        repetition_id = config.get('repetition_id', ''),
        wdir = WDIR
    output:
        f"{SPECIES_DIR}/run.smk"
    shell:
        '''
        cp {params.template_file} {output}
        sed -i "s|config\\['species_id'\\]|'{params.species_id}'|g" {output}
        sed -i "s|config\\['taxonomy_id'\\]|{params.taxonomy_id}|g" {output}
        sed -i "s|config\\.get('repetition_id', '')|'{params.repetition_id}'|g" {output}
        sed -i "s|config\\['wdir'\\]|'{params.wdir}'|g" {output}
        '''

rule clean:
    shell:
        '''
        rm {SPECIES_DIR}/run.smk {SPECIES_DIR}/output
        '''