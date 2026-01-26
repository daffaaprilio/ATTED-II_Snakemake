from pathlib import Path
import glob

'''
A special upload Snakefile for Ath. Ath-r is divided into: (1) Ath-r (true Ath, only contains the standard ecotype: Columbia); (2) Ath-e (contains ecotypes other than Columbia)
The coexpression calculation script involved 3 different directories, hence the upload preparation behaviour differs.
'''

WDIR = "/home/daffa/Work/2025/11-ATTED-II_ver-13.0"
ECOTYPE_DIR = WDIR 
CORE_DIR = WDIR
UPLOAD_DIR = f"{WDIR}/upload"

NEW_DATA_LIST = config['out_file']

PUB_VER_CORE = config['public_version_core']
PUB_VER_ECO = config['public_version_eco']

PUB_DIR_CORE = f"{UPLOAD_DIR}/coex/{PUB_VER_CORE}"
PUB_DIR_UNZIP_CORE = f"{UPLOAD_DIR}/coex_unzip/{PUB_VER_CORE}"
PUB_DIR_ECO = f"{UPLOAD_DIR}/coex/{PUB_VER_ECO}" 
PUB_DIR_UNZIP_ECO = f"{UPLOAD_DIR}/coex_unzip/{PUB_VER_ECO}"

SP_CORE = PUB_VER_CORE[:5]
SP_ECO = PUB_VER_ECO[:5]

OFC_DATE = "2026.02.16"
TYPE_ECO = "z"
TYPE_CORE = "z"
METHOD_ECO = "r26"
METHOD_CORE = "r26"

EXPR_COMBAT_CORE = f"{PUB_DIR_CORE}/{PUB_VER_CORE}.expression.combat.txt"
EXPR_PC_CORE = f"{PUB_DIR_CORE}/{PUB_VER_CORE}.expression.PC.txt"  
EXPR_COMBAT_ECO = f"{PUB_DIR_ECO}/{PUB_VER_ECO}.expression.combat.txt"  
EXPR_PC_ECO = f"{PUB_DIR_ECO}/{PUB_VER_ECO}.expression.PC.txt"  # 


# ==== PRIV_VER (coex data directory name) =====
# Extract private version names from coexpression data files in Ath-r_ecotype
ECOTYPE_SP_DIR = f"{WDIR}/Ath-r_ecotype"

# Core version
C_PATH_CORE = glob.glob(f"{ECOTYPE_SP_DIR}/79m_logit_mrgeo*.core.subagging.core.c")[0]
C_FILE_CORE = Path(C_PATH_CORE).name
# Extract PRIV_VER_CORE from filename: 79m_logit_mrgeo.{PRIV_VER}.combat_pca.core.subagging.core.c
PRIV_VER_CORE = C_FILE_CORE.replace("79m_logit_mrgeo.", "").replace(".combat_pca.core.subagging.core.c", "")

# Ecotype version
C_PATH_ECO = glob.glob(f"{ECOTYPE_SP_DIR}/79m_logit_mrgeo*.ecotype.subagging.ecotype.c")[0]
C_FILE_ECO = Path(C_PATH_ECO).name
# Extract PRIV_VER_ECO from filename: 79m_logit_mrgeo.{PRIV_VER}.combat_pca.ecotype.subagging.ecotype.c
PRIV_VER_ECO = C_FILE_ECO.replace("79m_logit_mrgeo.", "").replace(".combat_pca.ecotype.subagging.ecotype.c", "")

# ==== Populate new data list (a .tsv file containing list of coex data to upload in the current ATTED-II version)
new_line_core = f"{PUB_VER_CORE}\t{PRIV_VER_CORE}.{TYPE_CORE}.d"
new_line_eco = f"{PUB_VER_ECO}\t{PRIV_VER_ECO}.{TYPE_ECO}.d"

try:
    with open(NEW_DATA_LIST, 'r') as f:
        existing_lines = f.read().splitlines()
except FileNotFoundError:
    existing_lines = []

# Add core dataset line
if new_line_core.split('\t')[0] not in [line.split('\t')[0] for line in existing_lines]:
    with open(NEW_DATA_LIST, 'a') as f:
        f.write(f"\n{new_line_core}")

# Add ecotype dataset line
if new_line_eco.split('\t')[0] not in [line.split('\t')[0] for line in existing_lines]:
    with open(NEW_DATA_LIST, 'a') as f:
        f.write(f"\n{new_line_eco}")

# Define source directories
ATH_R_DIR = f"{WDIR}/Ath-r"
ATH_E_DIR = f"{WDIR}/Ath-e"

print(f"=== Processing Ath datasets version: {PUB_VER_CORE} & {PUB_VER_ECO} ===")

rule all:
    input:
        # CORE dataset files
        f"{PUB_DIR_CORE}/date", f"{PUB_DIR_CORE}/method", f"{PUB_DIR_CORE}/type", f"{PUB_DIR_CORE}/genes.txt", f"{PUB_DIR_CORE}/KEGG",
        f"{PUB_DIR_CORE}/{PUB_VER_CORE}.run_info.txt", f"{PUB_DIR_CORE}/{PUB_VER_CORE}.study_info.txt", f"{PUB_DIR_CORE}/{PUB_VER_CORE}.id-id-title.txt", 
        f"{PUB_DIR_CORE}/pc_select_exp.txt", f"{PUB_DIR_CORE}/pc_select_run.txt", f"{PUB_DIR_CORE}/pc_select_run.txt.zip", f"{PUB_DIR_CORE}/pc_select_run.txt.zip.md5.txt",
        f"{EXPR_COMBAT_CORE}", f"{EXPR_COMBAT_CORE}.zip", f"{EXPR_COMBAT_CORE}.zip.md5.txt", f"{EXPR_COMBAT_CORE}.zip.sha256.txt", 
        f"{EXPR_COMBAT_CORE}.tar.bz2", f"{EXPR_COMBAT_CORE}.tar.bz2.md5.txt", f"{EXPR_COMBAT_CORE}.tar.bz2.sha256.txt",
        f"{EXPR_PC_CORE}", f"{EXPR_PC_CORE}.zip", f"{EXPR_PC_CORE}.zip.md5.txt",
        f"{PUB_DIR_CORE}/{C_FILE_CORE}",
        f"{PUB_DIR_CORE}/{PRIV_VER_CORE}.{TYPE_CORE}.d.zip", f"{PUB_DIR_CORE}/{PRIV_VER_CORE}.{TYPE_CORE}.d.zip.md5.txt", f"{PUB_DIR_CORE}/{PRIV_VER_CORE}.{TYPE_CORE}.d.zip.sha256.txt",
        f"{UPLOAD_DIR}/coex_unzip/{PUB_VER_CORE}/{PRIV_VER_CORE}.{TYPE_CORE}.d/",
        # ECO dataset files
        f"{PUB_DIR_ECO}/date", f"{PUB_DIR_ECO}/method", f"{PUB_DIR_ECO}/type", f"{PUB_DIR_ECO}/genes.txt", f"{PUB_DIR_ECO}/KEGG",
        f"{PUB_DIR_ECO}/{PUB_VER_ECO}.run_info.txt", f"{PUB_DIR_ECO}/{PUB_VER_ECO}.study_info.txt", f"{PUB_DIR_ECO}/{PUB_VER_ECO}.id-id-title.txt",
        f"{PUB_DIR_ECO}/pc_select_exp.txt", f"{PUB_DIR_ECO}/pc_select_run.txt", f"{PUB_DIR_ECO}/pc_select_run.txt.zip", f"{PUB_DIR_ECO}/pc_select_run.txt.zip.md5.txt",
        f"{EXPR_COMBAT_ECO}", f"{EXPR_COMBAT_ECO}.zip", f"{EXPR_COMBAT_ECO}.zip.md5.txt", f"{EXPR_COMBAT_ECO}.zip.sha256.txt",
        f"{EXPR_COMBAT_ECO}.tar.bz2", f"{EXPR_COMBAT_ECO}.tar.bz2.md5.txt", f"{EXPR_COMBAT_ECO}.tar.bz2.sha256.txt",
        f"{EXPR_PC_ECO}", f"{EXPR_PC_ECO}.zip", f"{EXPR_PC_ECO}.zip.md5.txt",
        f"{PUB_DIR_ECO}/{C_FILE_ECO}",
        f"{PUB_DIR_ECO}/{PRIV_VER_ECO}.{TYPE_ECO}.d.zip", f"{PUB_DIR_ECO}/{PRIV_VER_ECO}.{TYPE_ECO}.d.zip.md5.txt", f"{PUB_DIR_ECO}/{PRIV_VER_ECO}.{TYPE_ECO}.d.zip.sha256.txt",
        f"{UPLOAD_DIR}/coex_unzip/{PUB_VER_ECO}/{PRIV_VER_ECO}.{TYPE_ECO}.d/"

# ===== CORE dataset rules =====
rule official_date_core:
    output: 
        f"{PUB_DIR_CORE}/date"
    shell:
        '''
        touch {output}
        echo {OFC_DATE} > {output}
        '''

rule method_core:
    output:
        f"{PUB_DIR_CORE}/method"
    params:
        method = METHOD_CORE
    shell:
        '''
        touch {output}
        echo {params.method} > {output}
        '''

rule type_core:
    output:
        f"{PUB_DIR_CORE}/type"
    params:
        type_val = TYPE_CORE
    shell:
        '''
        touch {output}
        echo {params.type_val} > {output}
        '''

rule kegg_core:
    output:
        f"{PUB_DIR_CORE}/KEGG"
    input:
        f"{ECOTYPE_SP_DIR}/score.KEGG50.KEGG.2025-12-15.Ath-r_ecotype.core.2026-01-23"
    shell:
        '''
        cp -p {input} {output}
        '''

rule genes_core:
    output:
        f"{PUB_DIR_CORE}/genes.txt"
    input:
        f"{ECOTYPE_SP_DIR}/paste.expression.combat.core.txt"
    shell:
        '''
        cut -f1 {input} | tail -n +2 > {output}
        '''

# CORE sample/study information
rule info_loadings_files_core:
    output:
        run_info = f"{PUB_DIR_CORE}/{PUB_VER_CORE}.run_info.txt",
        study_info = f"{PUB_DIR_CORE}/{PUB_VER_CORE}.study_info.txt",
        id_title = f"{PUB_DIR_CORE}/{PUB_VER_CORE}.id-id-title.txt",
        pc_run = f"{PUB_DIR_CORE}/pc_select_run.txt",
        pc_exp = f"{PUB_DIR_CORE}/pc_select_exp.txt",
        pc_run_zip = f"{PUB_DIR_CORE}/pc_select_run.txt.zip"
    input:
        run_info = f"{ATH_R_DIR}/run_info.txt",
        study_info = f"{ATH_R_DIR}/study_info.txt",
        id_title = f"{ATH_R_DIR}/id-id-title.txt",
        pc_run = f"{ATH_R_DIR}/pc_select_run.txt",
        pc_exp = f"{ATH_R_DIR}/pc_select_exp.txt"
    shell:
        '''
        cp -p {input.run_info} {output.run_info}
        cp -p {input.study_info} {output.study_info}
        cp -p {input.id_title} {output.id_title}
        cp -p {input.pc_run} {output.pc_run}
        cp -p {input.pc_exp} {output.pc_exp}
        zip -q {output.pc_run_zip} {output.pc_run}
        '''

# CORE expression files
rule expression_data_core:
    input:
        combat = f"{ECOTYPE_SP_DIR}/paste.expression.combat.core.txt",
        pc = f"{ECOTYPE_SP_DIR}/gc.d.core/1.gc"
    output: 
        combat_main = EXPR_COMBAT_CORE,
        combat_zip = f"{EXPR_COMBAT_CORE}.zip",
        combat_tar = f"{EXPR_COMBAT_CORE}.tar.bz2",
        pc_main = EXPR_PC_CORE,
        pc_zip = f"{EXPR_PC_CORE}.zip"
    shell:
        '''
        cp -p {input.combat} {output.combat_main}
        zip -q {output.combat_zip} {output.combat_main}
        tar -jcvf {output.combat_tar} {output.combat_main}
        cp -p {input.pc} {output.pc_main}
        zip -q {output.pc_zip} {output.pc_main}
        '''

# CORE coexpression files
rule coexpression_data_core:
    output:
        c_file = f"{PUB_DIR_CORE}/{C_FILE_CORE}",
        coex_zip = f"{PUB_DIR_CORE}/{PRIV_VER_CORE}.{TYPE_CORE}.d.zip",
        coex_unzip = directory(f"{UPLOAD_DIR}/coex_unzip/{PUB_VER_CORE}/{PRIV_VER_CORE}.{TYPE_CORE}.d/")
    input:
        c_path = C_PATH_CORE,
        nlmr_dir = f"{ECOTYPE_SP_DIR}/nlmr.d.core"
    shell:
        '''
        mkdir -p {output.coex_unzip}
        rsync -a {input.nlmr_dir}/ {output.coex_unzip}/
        zip -rq {output.coex_zip} {output.coex_unzip}/
        cp -p {input.c_path} {output.c_file} 
        '''

# CORE checksums
rule checksums_core:
    input:
        combat_zip = rules.expression_data_core.output.combat_zip,
        combat_tar = rules.expression_data_core.output.combat_tar,
        pc_zip = rules.expression_data_core.output.pc_zip,
        coex_zip = rules.coexpression_data_core.output.coex_zip,
        pc_run_zip = rules.info_loadings_files_core.output.pc_run_zip
    output:
        combat_zip_md5 = f"{EXPR_COMBAT_CORE}.zip.md5.txt",
        combat_zip_sha256 = f"{EXPR_COMBAT_CORE}.zip.sha256.txt",
        combat_tar_md5 = f"{EXPR_COMBAT_CORE}.tar.bz2.md5.txt",
        combat_tar_sha256 = f"{EXPR_COMBAT_CORE}.tar.bz2.sha256.txt",
        pc_zip_md5 = f"{EXPR_PC_CORE}.zip.md5.txt",
        coex_zip_md5 = f"{PUB_DIR_CORE}/{PRIV_VER_CORE}.{TYPE_CORE}.d.zip.md5.txt",
        coex_zip_sha256 = f"{PUB_DIR_CORE}/{PRIV_VER_CORE}.{TYPE_CORE}.d.zip.sha256.txt",
        pc_run_zip_md5 = f"{PUB_DIR_CORE}/pc_select_run.txt.zip.md5.txt"
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

# ===== ECO dataset rules =====
rule official_date_eco:
    output: 
        f"{PUB_DIR_ECO}/date"
    shell:
        '''
        touch {output}
        echo {OFC_DATE} > {output}
        '''

rule method_eco:
    output:
        f"{PUB_DIR_ECO}/method"
    params:
        method = METHOD_ECO
    shell:
        '''
        touch {output}
        echo {params.method} > {output}
        '''

rule type_eco:
    output:
        f"{PUB_DIR_ECO}/type"
    params:
        type_val = TYPE_ECO
    shell:
        '''
        touch {output}
        echo {params.type_val} > {output}
        '''

rule kegg_eco:
    output:
        f"{PUB_DIR_ECO}/KEGG"
    input:
        f"{ECOTYPE_SP_DIR}/score.KEGG50.KEGG.2025-12-15.Ath-r_ecotype.ecotype.2026-01-23"
    shell:
        '''
        cp -p {input} {output}
        '''

rule genes_eco:
    output:
        f"{PUB_DIR_ECO}/genes.txt"
    input:
        f"{ECOTYPE_SP_DIR}/paste.expression.combat.ecotype.txt"
    shell:
        '''
        cut -f1 {input} | tail -n +2 > {output}
        '''

# ECO sample/study information
rule info_loadings_files_eco:
    output:
        run_info = f"{PUB_DIR_ECO}/{PUB_VER_ECO}.run_info.txt",
        study_info = f"{PUB_DIR_ECO}/{PUB_VER_ECO}.study_info.txt",
        id_title = f"{PUB_DIR_ECO}/{PUB_VER_ECO}.id-id-title.txt",
        pc_run = f"{PUB_DIR_ECO}/pc_select_run.txt",
        pc_exp = f"{PUB_DIR_ECO}/pc_select_exp.txt",
        pc_run_zip = f"{PUB_DIR_ECO}/pc_select_run.txt.zip"
    input:
        run_info = f"{ATH_E_DIR}/run_info.txt",
        study_info = f"{ATH_E_DIR}/study_info.txt",
        id_title = f"{ATH_E_DIR}/id-id-title.txt",
        pc_run = f"{ATH_E_DIR}/pc_select_run.txt",
        pc_exp = f"{ATH_E_DIR}/pc_select_exp.txt"
    shell:
        '''
        cp -p {input.run_info} {output.run_info}
        cp -p {input.study_info} {output.study_info}
        cp -p {input.id_title} {output.id_title}
        cp -p {input.pc_run} {output.pc_run}
        cp -p {input.pc_exp} {output.pc_exp}
        zip -q {output.pc_run_zip} {output.pc_run}
        '''

# ECO expression files
rule expression_data_eco:
    input:
        combat = f"{ECOTYPE_SP_DIR}/paste.expression.combat.ecotype.txt",
        pc = f"{ECOTYPE_SP_DIR}/gc.d.ecotype/1.gc"
    output: 
        combat_main = EXPR_COMBAT_ECO,
        combat_zip = f"{EXPR_COMBAT_ECO}.zip",
        combat_tar = f"{EXPR_COMBAT_ECO}.tar.bz2",
        pc_main = EXPR_PC_ECO,
        pc_zip = f"{EXPR_PC_ECO}.zip"
    shell:
        '''
        cp -p {input.combat} {output.combat_main}
        zip -q {output.combat_zip} {output.combat_main}
        tar -jcvf {output.combat_tar} {output.combat_main}
        cp -p {input.pc} {output.pc_main}
        zip -q {output.pc_zip} {output.pc_main}
        '''

# ECO coexpression files
rule coexpression_data_eco:
    output:
        c_file = f"{PUB_DIR_ECO}/{C_FILE_ECO}",
        coex_zip = f"{PUB_DIR_ECO}/{PRIV_VER_ECO}.{TYPE_ECO}.d.zip",
        coex_unzip = directory(f"{UPLOAD_DIR}/coex_unzip/{PUB_VER_ECO}/{PRIV_VER_ECO}.{TYPE_ECO}.d/")
    input:
        c_path = C_PATH_ECO,
        nlmr_dir = f"{ECOTYPE_SP_DIR}/nlmr.d.ecotype"
    shell:
        '''
        mkdir -p {output.coex_unzip}
        rsync -a {input.nlmr_dir}/ {output.coex_unzip}/
        zip -rq {output.coex_zip} {output.coex_unzip}/
        cp -p {input.c_path} {output.c_file} 
        '''

# ECO checksums
rule checksums_eco:
    input:
        combat_zip = rules.expression_data_eco.output.combat_zip,
        combat_tar = rules.expression_data_eco.output.combat_tar,
        pc_zip = rules.expression_data_eco.output.pc_zip,
        coex_zip = rules.coexpression_data_eco.output.coex_zip,
        pc_run_zip = rules.info_loadings_files_eco.output.pc_run_zip
    output:
        combat_zip_md5 = f"{EXPR_COMBAT_ECO}.zip.md5.txt",
        combat_zip_sha256 = f"{EXPR_COMBAT_ECO}.zip.sha256.txt",
        combat_tar_md5 = f"{EXPR_COMBAT_ECO}.tar.bz2.md5.txt",
        combat_tar_sha256 = f"{EXPR_COMBAT_ECO}.tar.bz2.sha256.txt",
        pc_zip_md5 = f"{EXPR_PC_ECO}.zip.md5.txt",
        coex_zip_md5 = f"{PUB_DIR_ECO}/{PRIV_VER_ECO}.{TYPE_ECO}.d.zip.md5.txt",
        coex_zip_sha256 = f"{PUB_DIR_ECO}/{PRIV_VER_ECO}.{TYPE_ECO}.d.zip.sha256.txt",
        pc_run_zip_md5 = f"{PUB_DIR_ECO}/pc_select_run.txt.zip.md5.txt"
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
        rm -rf {PUB_DIR_CORE}/*
        rm -rf {PUB_DIR_ECO}/*
        '''