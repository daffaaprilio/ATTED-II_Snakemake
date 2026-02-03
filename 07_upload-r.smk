from pathlib import Path
import glob

WDIR = "/home/daffa/Work/2025/11-ATTED-II_ver-13.0"
RNA_DIR = "/home/daffa/Work/2025/11-ATTED-II_ver-13.0"
UPLOAD_DIR = f"{WDIR}/upload"

PUB_VER = config['public_version']
PUB_DIR = f"{UPLOAD_DIR}/coex/{PUB_VER}"
PUB_DIR_UNZIP = f"{UPLOAD_DIR}/coex_unzip/{PUB_VER}"
SP = PUB_VER[:5]
OFC_DATE = "2026.02.16"
METHOD = "r26"
TYPE = "z"
NEW_DATA_LIST = config['out_file']

# files in public directory base name 
## expression data
EXPR_COMBAT = f"{PUB_DIR}/{PUB_VER}.expression.combat.txt"
EXPR_PC = f"{PUB_DIR}/{PUB_VER}.expression.PC.txt"
## .c file and private version (coexpression data)
C_PATH = glob.glob(f"{WDIR}/{SP}/79m_logit_mrgeo*.c")[0] # full path to the C file
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
1. Prepare a directory named upload/coex/Xxx-r.c?-? and upload/coex_unzip/Xxx-r.c?-?
2. Each Public Directory contains information files, sample/study information, PCA selection metadata, expression data, and coexpression data
3. Each Unzip Public Directory contains private directory
'''

print(f"=== Processing RNA version: {PUB_VER} ===")

rule all:
    input:
        f"{PUB_DIR}/date", f"{PUB_DIR}/method", f"{PUB_DIR}/type", f"{PUB_DIR}/genes.txt", f"{PUB_DIR}/KEGG",
        f"{PUB_DIR}/{PUB_VER}.run_info.txt", f"{PUB_DIR}/{PUB_VER}.study_info.txt", f"{PUB_DIR}/{PUB_VER}.id-id-title.txt", f"{PUB_DIR}/pc_select_exp.txt", f"{PUB_DIR}/pc_select_run.txt", f"{PUB_DIR}/pc_select_run.txt.zip", f"{PUB_DIR}/pc_select_run.txt.zip.md5.txt",
        f"{EXPR_COMBAT}", f"{EXPR_COMBAT}.zip", f"{EXPR_COMBAT}.zip.md5.txt", f"{EXPR_COMBAT}.zip.sha256.txt", f"{EXPR_COMBAT}.tar.bz2", f"{EXPR_COMBAT}.tar.bz2.md5.txt", f"{EXPR_COMBAT}.tar.bz2.sha256.txt",
        f"{EXPR_PC}", f"{EXPR_PC}.zip", f"{EXPR_PC}.zip.md5.txt",
        f"{PUB_DIR}/{C_FILE}",
        f"{PUB_DIR}/{PRIV_VER}.{TYPE}.d.zip", f"{PUB_DIR}/{PRIV_VER}.{TYPE}.d.zip.md5.txt", f"{PUB_DIR}/{PRIV_VER}.{TYPE}.d.zip.sha256.txt",  
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
        glob.glob(f"{RNA_DIR}/{SP}/score.KEGG*")[0]
    shell:
        '''
        cp -p {input} {output}
        '''

rule genes:
    output:
        f"{PUB_DIR}/genes.txt"
    input:
        f"{RNA_DIR}/{SP}/paste.expression.combat"
    shell:
        '''
        cut -f1 {input} | tail -n +2 > {output}
        '''

# sample/study information
rule info_loadings_files:
    output:
        run_info = f"{PUB_DIR}/{PUB_VER}.run_info.txt",
        study_info = f"{PUB_DIR}/{PUB_VER}.study_info.txt",
        id_title = f"{PUB_DIR}/{PUB_VER}.id-id-title.txt",
        pc_run = f"{PUB_DIR}/pc_select_run.txt",
        pc_exp = f"{PUB_DIR}/pc_select_exp.txt",
        pc_run_zip = f"{PUB_DIR}/pc_select_run.txt.zip"
    input:
        run_info = f"{RNA_DIR}/{SP}/run_info.txt",
        study_info = f"{RNA_DIR}/{SP}/study_info.txt",
        id_title = f"{RNA_DIR}/{SP}/id-id-title.txt",
        pc_run = f"{RNA_DIR}/{SP}/pc_select_run.txt",
        pc_exp = f"{RNA_DIR}/{SP}/pc_select_exp.txt"
    shell:
        '''
        cp -p {input.run_info} {output.run_info}
        cp -p {input.study_info} {output.study_info}
        cp -p {input.id_title} {output.id_title}
        cp -p {input.pc_run} {output.pc_run}
        cp -p {input.pc_exp} {output.pc_exp}
        zip -q {output.pc_run_zip} {output.pc_run}
        '''

# expresssion files
rule expression_data:
    input:
        combat = f"{RNA_DIR}/{SP}/paste.expression.combat",
        pc = f"{RNA_DIR}/{SP}/gc.d/1.gc"
    output: 
        combat_main = EXPR_COMBAT,
        combat_zip = f"{EXPR_COMBAT}.zip",
        combat_tar = f"{EXPR_COMBAT}.tar.bz2",
        pc_main = EXPR_PC,
        pc_zip = f"{EXPR_PC}.zip"
    shell:
        '''
        cp -p {input.combat} {output.combat_main}
        zip -q {output.combat_zip} {output.combat_main}
        tar -jcvf {output.combat_tar} {output.combat_main}
        cp -p {input.pc} {output.pc_main}
        zip -q {output.pc_zip} {output.pc_main}
        '''

# coexpression files
rule coexpression_data:
    output:
        c_file = f"{PUB_DIR}/{C_FILE}",
        coex_zip = f"{PUB_DIR}/{PRIV_VER}.{TYPE}.d.zip",
        coex_unzip = directory(f"{UPLOAD_DIR}/coex_unzip/{PUB_VER}/{PRIV_VER}.{TYPE}.d/")
    input:
        c_path = C_PATH,
        nlmr_dir = f"{RNA_DIR}/{SP}/nlmr.d"
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
        pc_zip = rules.expression_data.output.pc_zip,
        coex_zip = rules.coexpression_data.output.coex_zip,
        pc_run_zip = rules.info_loadings_files.output.pc_run_zip
    output:
        combat_zip_md5 = f"{EXPR_COMBAT}.zip.md5.txt",
        combat_zip_sha256 = f"{EXPR_COMBAT}.zip.sha256.txt",
        combat_tar_md5 = f"{EXPR_COMBAT}.tar.bz2.md5.txt",
        combat_tar_sha256 = f"{EXPR_COMBAT}.tar.bz2.sha256.txt",
        pc_zip_md5 = f"{EXPR_PC}.zip.md5.txt",
        coex_zip_md5 = f"{PUB_DIR}/{PRIV_VER}.{TYPE}.d.zip.md5.txt",
        coex_zip_sha256 = f"{PUB_DIR}/{PRIV_VER}.{TYPE}.d.zip.sha256.txt",
        pc_run_zip_md5 = f"{PUB_DIR}/pc_select_run.txt.zip.md5.txt"
    shell:
        '''
        (cd $(dirname {input.combat_zip}) && md5sum $(basename {input.combat_zip})) > {output.combat_zip_md5}
        (cd $(dirname {input.combat_zip}) && sha256sum $(basename {input.combat_zip})) > {output.combat_zip_sha256}
        (cd $(dirname {input.combat_tar}) && md5sum $(basename {input.combat_tar})) > {output.combat_tar_md5}
        (cd $(dirname {input.combat_tar}) && sha256sum $(basename {input.combat_tar})) > {output.combat_tar_sha256}
        (cd $(dirname {input.pc_zip}) && md5sum $(basename {input.pc_zip})) > {output.pc_zip_md5}
        (cd $(dirname {input.coex_zip}) && md5sum $(basename {input.coex_zip})) > {output.coex_zip_md5}
        (cd $(dirname {input.coex_zip}) && sha256sum $(basename {input.coex_zip})) > {output.coex_zip_sha256}
        (cd $(dirname {input.pc_run_zip}) && md5sum $(basename {input.pc_run_zip})) > {output.pc_run_zip_md5}
        '''

rule clean:
    shell:
        '''
        rm -rf {PUB_DIR}/*
        '''