from datetime import datetime

WDIR = "/home/daffa/Work/2025/11-ATTED-II_ver-13.0"
cutSP = config['species_id']
TAXONOMY_ID = config['taxonomy_id']

REP_NO = f"_{config.get('repetition_id', '')}" if config.get('repetition_id', '') else ""

# SP is for: SPECIES_ID + type (RNA, microarray, etc.)
SP = f"{cutSP}-u{REP_NO}"
SPECIES_DIR = f"{WDIR}/{SP}"

# step specific synonyms
KEGG_ftp_date = "2025-12-15"
EVAL_DATE = datetime.now().strftime('%Y-%m-%d')
LOG_DATETIME = datetime.now().strftime('%Y%m%d_%H%M%S')

UNION_GENE_DIR = directory(f"{SPECIES_DIR}/{SP}")
EVAL_OUTPUT = f"{SPECIES_DIR}/score.KEGG50.KEGG.{KEGG_ftp_date}.{SP}.{EVAL_DATE}"

rule all:
    input:
        UNION_GENE_DIR,
        EVAL_OUTPUT

rule unionizing:
    input:
        f"{cutSP}-m",
        f"{cutSP}-r"
    output:
        UNION_GENE_DIR
    log:
        f"{SPECIES_DIR}/logs/unionizing.{LOG_DATETIME}.log"
    shell:
        '''
        exec > {log} 2>&1
        echo "New calculation for {SP}"
        echo "\n(1) Processing union..."
        date
        cd {SPECIES_DIR}
        pwd;
        Rscript {WDIR}/scripts/2-Subsampling/x02-union.R -s {cutSP}
        echo "\nFinished for {SP}."
        '''

rule evaluation:
    input:
        UNION_GENE_DIR
    params:
        kegg_date = KEGG_ftp_date
    output:
        EVAL_OUTPUT
    log:
        f"{SPECIES_DIR}/logs/evaluation.{LOG_DATETIME}.log"
    shell:
        '''
        exec > {log} 2>&1
        echo "\n(2) Performance evaluation..."
        date 
        cd {SPECIES_DIR}
        {WDIR}/Eval/score_excl_paralog_pair.pl -s {cutSP} -K {WDIR}/Eval/KEGG.{params.kegg_date}/KEGG50 -g {WDIR}/Eval/ko-genes.{params.kegg_date}/{cutSP} -d {cutSP}-u -o {output} || true
        echo "\nFinished for {SP}."
        '''