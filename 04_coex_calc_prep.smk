
WDIR = config['wdir']
SPECIES_ID = config['species_id']
TAXONOMY_ID = config['taxonomy_id']

'''
1. Create species directory
2. In species directory, create symbolic link to the output file
2. In species directory, create batchrun script for each species in the species directory
'''

SPECIES_DIR = f"{WDIR}/{SPECIES_ID}-r"
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
        template_file = f"{WDIR}/06_coex_calc_template.smk"
    output:
        f"{SPECIES_DIR}/run.smk"
    shell:
        '''
        touch {output}
        cat {params.template_file} > {output}
        '''