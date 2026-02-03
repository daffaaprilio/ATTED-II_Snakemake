from pathlib import Path
import glob

WDIR = "/home/daffa/Work/2025/11-ATTED-II_ver-13.0"
UNION_DIR = "/home/daffa/Work/2025/11-ATTED-II_ver-13.0"
UPLOAD_DIR = f"{WDIR}/upload"
PREV_UPLOAD_DIR = f"{WDIR}/upload_prev_microarray"

PUB_VER = config['public_version']
PUB_DIR = f"{UPLOAD_DIR}/coex/{PUB_VER}"
PUB_DIR_UNZIP = f"{UPLOAD_DIR}/coex_unzip/{PUB_VER}"
SP = PUB_VER[:5]
OFC_DATE = "2026.02.16"
METHOD = "u22"
TYPE = "z"
NEW_DATA_LIST = config['out_file']

# Find microarray and RNA-seq versions for "from" file
m_versions = glob.glob(f"{PREV_UPLOAD_DIR}/coex/{SP[:3]}-m*")
r_versions = glob.glob(f"{UPLOAD_DIR}/coex/{SP[:3]}-r*")

# Get RNA version's C file to derive private version (required for union)
if not r_versions:
    raise ValueError(f"No RNA version found for {SP[:3]}-r. Union requires RNA version to exist.")

c_files = glob.glob(f"{UPLOAD_DIR}/coex/{SP[:3]}-r*/79m_logit_mrgeo*.c")
if not c_files:
    raise ValueError(f"No C file found in RNA version directory for {SP[:3]}-r")

C_PATH = c_files[0]  # full path to the C file (of the RNA version). for Ath, it is ['./upload/coex/Ath-r.c7-0/79m_logit_mrgeo.Ath-r.v26-01.P19674-S19674.combat_pca.core.subagging.core.c']
C_FILE = Path(C_PATH).name  # just the full name of the C file
stem = Path(C_PATH).stem
if 'Ath' in stem:
    stem = stem.replace('-r', '-u')
    stem = stem.replace('combat_pca.core.subagging.core', 'combat_pca.subagging')
else:
    stem = stem.replace('-r', '-u') # rename private version from -r to -u
parts = stem.split('.')

# determine num p and num s for this union version
M_ZIP_PATH = glob.glob(f"{m_versions[0]}/*.d.zip")[0]
m_zip_stem = Path(M_ZIP_PATH).stem # Vvi-m.v21-01.G9421-S258.combat_pca_subagging.ls.d.zip
m_zip_parts = m_zip_stem.split('.') 
m_zip_num_s = m_zip_parts[2].split('-')[1]

num_p, num_s = parts[3].split('-')
num_p = num_p.replace('P', 'G')
num_s = f"S{int(num_s.replace('S', '')) + int(m_zip_num_s.replace('S', ''))}"

# Correction for num_s - use union sample count
if num_s.replace('S', '') == num_p.replace('G', ''):
    with open(f"{WDIR}/{SP}/list.txt", 'r') as f:
        num_s = f'S{sum(1 for line in f)}'

num_ps = '-'.join([num_p, num_s])
PRIV_VER = '.'.join(parts[1:3] + [num_ps] + parts[4:])  
PRIV_DIR = f"{UPLOAD_DIR}/coex_unzip/{PUB_VER}/{PRIV_VER}.{TYPE}.d"

# Create "from" content for union (lists both microarray and RNA versions)
FROM_CONTENT = ""
if m_versions and r_versions:
    m_ver = Path(m_versions[0]).name
    r_ver = Path(r_versions[0]).name
    FROM_CONTENT = f"{m_ver} {r_ver}\n"

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
1. Prepare a directory named upload/coex/Xxx-u.c?-? and upload/coex_unzip/Xxx-u.c?-?
2. Each Public Directory contains information files, sample/study information, and coexpression data (NO expression data for union)
3. Each Unzip Public Directory contains private directory
'''

print(f"=== Processing UNION version: {PUB_VER} ===")

rule all:
    input:
        f"{PUB_DIR}/date", f"{PUB_DIR}/method", f"{PUB_DIR}/type", f"{PUB_DIR}/KEGG", f"{PUB_DIR}/from", f"{PUB_DIR}/genes.txt",
        f"{UPLOAD_DIR}/coex_unzip/{PUB_VER}/{PRIV_VER}.{TYPE}.d/", f"{PUB_DIR}/{PRIV_VER}.{TYPE}.d.zip",
        f"{PUB_DIR}/{PRIV_VER}.{TYPE}.d.zip.md5.txt", f"{PUB_DIR}/{PRIV_VER}.{TYPE}.d.zip.sha256.txt"

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
        glob.glob(f"{UNION_DIR}/{SP}/score.KEGG*")[0]
    shell:
        '''
        cp -p {input} {output}
        '''

rule genes:
    output:
        f"{PUB_DIR}/genes.txt"
    input:
        coex_unzip = f"{UPLOAD_DIR}/coex_unzip/{PUB_VER}/{PRIV_VER}.{TYPE}.d/"
    shell:
        '''
        ls -1 {input.coex_unzip} | sort > {output}
        '''

rule from_file:
    output:
        f"{PUB_DIR}/from"
    shell:
        '''
        touch {output}
        echo "{FROM_CONTENT}" > {output}
        '''

# coexpression files
rule coexpression_data:
    output:
        coex_zip = f"{PUB_DIR}/{PRIV_VER}.{TYPE}.d.zip",
        coex_unzip = directory(f"{UPLOAD_DIR}/coex_unzip/{PUB_VER}/{PRIV_VER}.{TYPE}.d/")
    input:
        c_path = C_PATH,
        union_dir = f"{UNION_DIR}/{SP}/{SP}"
    shell:
        '''
        mkdir -p {output.coex_unzip}
        rsync -a {input.union_dir}/ {output.coex_unzip}/
        cd {UPLOAD_DIR}/coex_unzip/{PUB_VER} && zip -r {output.coex_zip} {PRIV_VER}.{TYPE}.d/
        '''

# checksums
rule checksums:
    input:
        coex_zip = rules.coexpression_data.output.coex_zip
    output:
        coex_zip_md5 = f"{PUB_DIR}/{PRIV_VER}.{TYPE}.d.zip.md5.txt",
        coex_zip_sha256 = f"{PUB_DIR}/{PRIV_VER}.{TYPE}.d.zip.sha256.txt"
    shell:
        '''
        (cd $(dirname {input.coex_zip}) && md5sum $(basename {input.coex_zip})) > {output.coex_zip_md5}
        (cd $(dirname {input.coex_zip}) && sha256sum $(basename {input.coex_zip})) > {output.coex_zip_sha256}
        '''

rule clean:
    shell:
        '''
        rm -rf {PUB_DIR}/*
        '''
