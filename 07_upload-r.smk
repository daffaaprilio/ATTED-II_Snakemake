from pathlib import Path
import glob

WDIR = "/home/daffa/Work/2025/11-ATTED-II_ver-13.0"
RNA_DIR = "/home/daffa/Work/2025/11-ATTED-II_ver-13.0"
UPLOAD_DIR = f"{WDIR}/upload"

PUB_VER = config['public_version']
PUB_DIR = f"{UPLOAD_DIR}/coex/{PUB_VER}"
PUB_DIR_UNZIP = f"{UPLOAD_DIR}/coex_ubzip/{PUB_VER}"
SP = PUB_VER[:5]
OFC_DATE = "2026.02.16"
METHOD = "r26"
TYPE = "ls"
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
PRIV_VER = '.'.join(parts[1:3] + [num_p, num_s] + parts[4:6]) 
PRIV_DIR = f"{PUB_DIR}/{PRIV_VER}.{TYPE}.d"

'''
1. Prepare a directory named upload/coex/Xxx-r.c?-? and upload/coex_ubzip/Xxx-r.c?-?
2. Each Public Directory contains information files, sample/study information, PCA selection metadata, expression data, and coexpression data
3. Each Ubzip Public Directory contains private directory
'''

rule all:
    input:
        NEW_DATA_LIST,
        f"{PUB_DIR}/date", f"{PUB_DIR}/method", f"{PUB_DIR}/type", f"{PUB_DIR}/genes.txt", f"{PUB_DIR}/KEGG",
        f"{PUB_DIR}/{PUB_VER}.run_info.txt", f"{PUB_DIR}/{PUB_VER}.study_info.txt", f"{PUB_DIR}/{PUB_VER}.id-id-title.txt", f"{PUB_DIR}/pc_select_run.txt", f"{PUB_DIR}/pc_select_exp.txt"
        f"{EXPR_COMBAT}", f"{EXPR_COMBAT}.zip", f"{EXPR_COMBAT}.zip.md5.txt", f"{EXPR_COMBAT}.zip.sha256.txt", f"{EXPR_COMBAT}.tar.bz2", f"{EXPR_COMBAT}.tar.bz2.md5.txt", f"{EXPR_COMBAT}.tar.bz2.sha256.txt",
        f"{EXPR_PC}", f"{EXPR_PC}.zip", f"{EXPR_PC}.zip.md5.txt",
        f"{PUB_DIR}/{C_FILE}"

rule populate_list:
    output:
        NEW_DATA_LIST
    run:      
        with open(output[0], 'w') as f:
            f.write(f"{PUB_VER}\t{PRIV_DIR}")

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
rule pca_loadings_info:
    output:
        run_info = f"{PUB_DIR}/{PUB_VER}.run_info.txt",
        study_info = f"{PUB_DIR}/{PUB_VER}.study_info.txt",
        id_title = f"{PUB_DIR}/{PUB_VER}.id-id-title.txt",
        pc_run = f"{PUB_DIR}/pc_select_run.txt",
        pc_exp = f"{PUB_DIR}/pc_select_exp.txt"
    input:
        run_info = f"{RNA_DIR}/{SP}/run_info.txt",
        study_info = f"{RNA_DIR}/{SP}/study_info.txt",
        id_title = f"{RNA_DIR}/{SP}/id-id-title.txt",
        pc_run = f"{RNA_DIR}/{SP}/pc_select_run.txt",
        pc_exp = f"{RNA_DIR}/{SP}/pc_select_exp.txt"
    shell:
        '''
        
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
        coex_zip = f"{PRIV_DIR}.zip",
        c_file = f"{PUB_DIR}/{C_FILE}"
    input:
        nlmr_dir = f"{RNA_DIR}/{SP}/nlmr.d",
        c_path = C_PATH
    shell:
        '''
        mkdir -p {PRIV_DIR}
        cp -p {input.nlmr_dir}/* {PRIV_DIR}/
        zip -rq {output.coex_zip} {PRIV_DIR}/
        rm -r {PRIV_DIR}
        cp -p {input.c_path} {output.c_file} 
        '''

# checksums
rule checksums:
    input:
        combat_zip = rules.expression_data.output.combat_zip,
        combat_tar = rules.expression_data.output.combat_tar,
        pc_zip = rules.expression_data.output.pc_zip,
        coex_zip = rules.coexpression_data.output.coex_zip
    output:
        combat_zip_md5 = f"{EXPR_COMBAT}.zip.md5.txt",
        combat_zip_sha256 = f"{EXPR_COMBAT}.zip.sha256.txt",
        combat_tar_md5 = f"{EXPR_COMBAT}.tar.bz2.md5.txt",
        combat_tar_sha256 = f"{EXPR_COMBAT}.tar.bz2.sha256.txt",
        pc_zip_md5 = f"{EXPR_PC}.zip.md5.txt",
        coex_zip_md5 = f"{PRIV_DIR}.zip.md5.txt",
        coex_zip_sha256 = f"{PRIV_DIR}.zip.sha256.txt"
    shell:
        '''
        md5sum {input.combat_zip} > {output.combat_zip_md5}
        sha256sum {input.combat_zip} > {output.combat_zip_sha256}
        md5sum {input.combat_tar} > {output.combat_tar_md5}
        sha256sum {input.combat_tar} > {output.combat_tar_sha256}
        md5sum {input.pc_zip} > {output.pc_zip_md5}
        md5sum {input.coex_zip} > {output.coex_zip_md5}
        sha256sum {input.coex_zip} > {output.coex_zip_sha256}
        '''

rule clean:
    shell:
        '''
        rm -rf {PUB_DIR}/*
        '''