from pathlib import Path
import glob

WDIR = "/home/daffa/Work/2025/11-ATTED-II_ver-13.0"
MICROARRAY_DIR = "/home/hibara/ATTED-II_ver.11.0"
UPLOAD_DIR = f"{WDIR}/upload"

PUB_VER = config['public_version']
PUB_DIR = f"{UPLOAD_DIR}/coex/{PUB_VER}"
PUB_DIR_UNZIP = f"{UPLOAD_DIR}/coex_unzip/{PUB_VER}"
SP = PUB_VER[:5]
OFC_DATE = "2026.02.16"
METHOD = "m21"
TYPE = "z"
NEW_DATA_LIST = config['out_file']

# files in public directory base name 
## expression data
EXPR_COMBAT = f"{PUB_DIR}/{PUB_VER}.expression.combat.txt"
## .c file and private version (coexpression data)
C_PATH = glob.glob(f"{MICROARRAY_DIR}/{SP}/79m_logit_mrgeo*.c")[0] # full path to the C file
C_FILE = Path(C_PATH).name # just the full name of the C file
stem = Path(C_PATH).stem
parts = stem.split('.')
num_p, num_s = parts[3].split('-')
num_p = num_p.replace('P', 'G')
### correction for num_s
if num_s.replace('S', '') == num_p.replace('G', ''):
    with open(f"{WDIR}/{SP}/list.txt", 'r') as f:
        num_s = f'S{sum(1 for line in f)}'
num_ps = '-'.join([num_p, num_s])
PRIV_VER = '.'.join(parts[1:3] + [num_ps] + parts[4:6]) 
PRIV_DIR = f"{UPLOAD_DIR}/coex_unzip/{PUB_VER}/{PRIV_VER}.{TYPE}.d"

# populate new data list
new_line = f"{PUB_VER}\t{PRIV_VER}.{TYPE}.d"
try:
    with open(NEW_DATA_LIST, 'r') as f:
        existing_lines = f.read().splitlines()
except FileNotFoundError:
    existing_lines = []

if new_line not in existing_lines:
    with open(NEW_DATA_LIST, 'a') as f:
        f.write(f"{new_line}\n")

'''
1. Prepare a directory named upload/coex/Xxx-m.c?-? and upload/coex_unzip/Xxx-m.c?-?
2. Each Public Directory contains information files, sample/study information, expression data, and coexpression data
3. Each Unzip Public Directory contains private directory
'''

print(f"=== Processing MICROARRAY version: {PUB_VER} ===")

rule all:
    input:
        f"{PUB_DIR}/date", f"{PUB_DIR}/method", f"{PUB_DIR}/type", f"{PUB_DIR}/genes.txt", f"{PUB_DIR}/KEGG",
        f"{PUB_DIR}/{PUB_VER}.id-id-title.txt",
        f"{EXPR_COMBAT}", f"{EXPR_COMBAT}.zip", f"{EXPR_COMBAT}.zip.md5.txt", f"{EXPR_COMBAT}.zip.sha256.txt", f"{EXPR_COMBAT}.tar.bz2", f"{EXPR_COMBAT}.tar.bz2.md5.txt", f"{EXPR_COMBAT}.tar.bz2.sha256.txt",
        f"{PUB_DIR}/{C_FILE}",
        f"{UPLOAD_DIR}/coex_unzip/{PUB_VER}/{PRIV_VER}.{TYPE}.d/"

# information files
rule official_date:
    output: 
        f"{PUB_DIR}/date"
    shell:
        '''
        touch {output}
        echo {OFC_DATE} > {output}
        '''

rule method:
    output:
        f"{PUB_DIR}/method"
    shell:
        '''
        touch {output}
        echo {METHOD} > {output}
        '''

rule type:
    output:
        f"{PUB_DIR}/type"
    shell:
        '''
        touch {output}
        echo {TYPE} > {output}
        '''

rule kegg:
    output:
        f"{PUB_DIR}/KEGG"
    input:
        glob.glob(f"{MICROARRAY_DIR}/{SP}/*kegg*")[0]
    shell:
        '''
        cp -p {input} {output}
        '''

rule genes:
    output:
        f"{PUB_DIR}/genes.txt"
    input:
        f"{MICROARRAY_DIR}/{SP}/paste.expression.combat"
    shell:
        '''
        cut -f1 {input} | tail -n +2 > {output}
        '''

# sample/study information
rule info_files:
    output:
        id_title = f"{PUB_DIR}/{PUB_VER}.id-id-title.txt"
    input:
        id_title = f"{MICROARRAY_DIR}/{SP}/id-id-title.txt"
    shell:
        '''
        cp -p {input.id_title} {output.id_title}
        '''

# expresssion files
rule expression_data:
    input:
        combat = f"{MICROARRAY_DIR}/{SP}/paste.expression.combat",
    output: 
        combat_main = EXPR_COMBAT,
        combat_zip = f"{EXPR_COMBAT}.zip",
        combat_tar = f"{EXPR_COMBAT}.tar.bz2",
    shell:
        '''
        cp -p {input.combat} {output.combat_main}
        zip -q {output.combat_zip} {output.combat_main}
        tar -jcvf {output.combat_tar} {output.combat_main}
        '''

# coexpression files
rule coexpression_data:
    output:
        c_file = f"{PUB_DIR}/{C_FILE}",
        coex_zip = f"{PUB_DIR}/{PRIV_VER}.{TYPE}.d.zip",
        coex_unzip = directory(f"{UPLOAD_DIR}/coex_unzip/{PUB_VER}/{PRIV_VER}.{TYPE}.d/")
    input:
        c_path = C_PATH,
        nlmr_dir = f"{MICROARRAY_DIR}/{SP}/nlmr.d"
    shell:
        '''
        mkdir -p {output.coex_unzip}
        rsync -a {input.nlmr_dir}/ {output.coex_unzip}/
        cd {UPLOAD_DIR}/coex_unzip/{PUB_VER} && zip -r {output.coex_zip} {PRIV_VER}.{TYPE}.d/
        cp -p {input.c_path} {output.c_file} 
        '''

# checksums
rule checksums:
    input:
        combat_zip = rules.expression_data.output.combat_zip,
        combat_tar = rules.expression_data.output.combat_tar,
        coex_zip = rules.coexpression_data.output.coex_zip
    output:
        combat_zip_md5 = f"{EXPR_COMBAT}.zip.md5.txt",
        combat_zip_sha256 = f"{EXPR_COMBAT}.zip.sha256.txt",
        combat_tar_md5 = f"{EXPR_COMBAT}.tar.bz2.md5.txt",
        combat_tar_sha256 = f"{EXPR_COMBAT}.tar.bz2.sha256.txt",
        coex_zip_md5 = f"{PUB_DIR}/{PRIV_VER}.{TYPE}.d.zip.md5.txt",
        coex_zip_sha256 = f"{PUB_DIR}/{PRIV_VER}.{TYPE}.d.zip.sha256.txt"
    shell:
        '''
        md5sum {input.combat_zip} > {output.combat_zip_md5}
        sha256sum {input.combat_zip} > {output.combat_zip_sha256}
        md5sum {input.combat_tar} > {output.combat_tar_md5}
        sha256sum {input.combat_tar} > {output.combat_tar_sha256}
        md5sum {input.coex_zip} > {output.coex_zip_md5}
        sha256sum {input.coex_zip} > {output.coex_zip_sha256}
        '''

rule clean:
    shell:
        '''
        rm -rf {PUB_DIR}/*
        '''

