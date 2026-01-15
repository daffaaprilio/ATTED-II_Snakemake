from datetime import datetime

WDIR = "/home/daffa/Work/2025/11-ATTED-II_ver-13.0"
cutSP = 'Ath'
TAXONOMY_ID = 3702

REP_NO = f"_{config.get('repetition_id', '')}" if config.get('repetition_id', '') else ""

# SP is for: SPECIES_ID + type (RNA, microarray, etc.)
SP = f"{cutSP}-r_ecotype{REP_NO}"
SP_CORE = f"{cutSP}-r{REP_NO}"
SP_ECO = f"{cutSP}-e{REP_NO}"
SPECIES_DIR = f"{WDIR}/{SP}"
SPECIES_CORE_DIR = f"{WDIR}/{SP_CORE}"
SPECIES_ECO_DIR = f"{WDIR}/{SP_ECO}"

# step specific parameters
PCA_TYPE = "double"
SUBAGGING_AVE = config.get('subagging_ave', '') if config.get('subagging_ave', '') else 1000
VALID_NUM = config.get('valid_num', '') if config.get('valid_num', '') else 1000
SAMPLING_RATE = config.get('sampling_rate', '') if config.get('sampling_rate', '') else 50
KEGG_ftp_date = "2025-12-15"
EVAL_DATE = datetime.now().strftime('%Y-%m-%d')
EVAL_CORE_OUTPUT = f"{SPECIES_DIR}/score.KEGG50.KEGG.{KEGG_ftp_date}.{SP}.core.{EVAL_DATE}"
EVAL_ECOTYPE_OUTPUT = f"{SPECIES_DIR}/score.KEGG50.KEGG.{KEGG_ftp_date}.{SP}.ecotype.{EVAL_DATE}"

rule all:
    input:
    f"{SPECIES_DIR}/key_pair",
    f"{SPECIES_DIR}/subagging.ecotype.logitMR.ave_{SUBAGGING_AVE}",
    f"{SPECIES_DIR}/subagging.core.logitMR.ave_{SUBAGGING_AVE}",
    f"{SPECIES_DIR}/nlmr.d.ecotype",
    f"{SPECIES_DIR}/nlmr.d.core",
    EVAL_ECOTYPE_OUTPUT,
    EVAL_CORE_OUTPUT

rule combat_pca:
    params:
        pca = PCA_TYPE
    input:
        f"{WDIR}/refseq/{cutSP}-r_SpeciesSpecific2EGI",
        f"{WDIR}/blacklist-run",
        f"{WDIR}/srainfo-study_table.txt"
    output:
        f"{SPECIES_DIR}/list_ecotype.txt",
        f"{SPECIES_DIR}/list_core.txt",
        f"{SPECIES_DIR}/key",
        f"{SPECIES_DIR}/gc.d.ecotype/1.gc",
        f"{SPECIES_DIR}/gc.d.core/1.gc",
        f"{SPECIES_DIR}/paste.expression.combat",
        f"{SPECIES_DIR}/pca_loadings_ecotype.txt",
        f"{SPECIES_DIR}/pca_loadings_core.txt"
    shell:
        '''
        cd {WDIR}
        Rscript {WDIR}/scripts/2-Subsampling/x-43-ComBat.RNA-seq.ecotype.R -s {SP} -p {params.pca}
        '''

rule loading_annotation_prep:
    shell:
        '''
        echo "loading annotation for Core"
        cd {SPECIES_CORE_DIR}
        ln -s {SPECIES_DIR}/pca_loadings_core.txt pca_loadings.txt
        ln -s {SPECIES_DIR}/list_core.txt list.txt
        echo "loading annotation for Ecotype"
        cd {SPECIES_ECO_DIR}
        ln -s {SPECIES_DIR}/pca_loadings_core.txt pca_loadings.txt
        ln -s {SPECIES_DIR}/list_core.txt list.txt
        '''

rule create_id_title:
    input:
        f"{SPECIES_CORE_DIR}/list.txt",
        f"{SPECIES_ECO_DIR}/list.txt",
        f"{WDIR}/srainfo.sqlite3"
    output:
        f"{SPECIES_CORE_DIR}/id-id-title.txt",
        f"{SPECIES_ECO_DIR}/id-id-title.txt"
    shell:
        '''
        cd {WDIR}
        python3 {WDIR}/scripts/1-PreSubsampling/x-61-create-id-id-title.py --sp {SP_ECO}
        python3 {WDIR}/scripts/1-PreSubsampling/x-61-create-id-id-title.py --sp {SP_CORE}
        '''

rule create_info:
    input:
        f"{SPECIES_CORE_DIR}/list.txt",
        f"{SPECIES_ECO_DIR}/list.txt",
        f"{WDIR}/srainfo.sqlite3"
    output:
        f"{SPECIES_CORE_DIR}/study_info.txt",
        f"{SPECIES_CORE_DIR}/run_info.txt",
        f"{SPECIES_ECO_DIR}/study_info.txt",
        f"{SPECIES_ECO_DIR}/run_info.txt"
    shell:
        '''
        cd {WDIR}
        python3 {WDIR}/scripts/1-PreSubsampling/x-62-info-txt.py --sp {SP_CORE}
        python3 {WDIR}/scripts/1-PreSubsampling/x-62-info-txt.py --sp {SP_ECO}
        '''

rule selecting:
    input:
        f"{SPECIES_ECO_DIR}/pca_loadings.txt",
        f"{SPECIES_ECO_DIR}/study_info.txt",
        f"{SPECIES_ECO_DIR}/run_info.txt",
        f"{SPECIES_CORE_DIR}/pca_loadings.txt",
        f"{SPECIES_CORE_DIR}/study_info.txt",
        f"{SPECIES_CORE_DIR}/run_info.txt"
    output:
        f"{SPECIES_ECO_DIR}/pc_select_run.txt",
        f"{SPECIES_ECO_DIR}/pc_select_exp.txt",
        f"{SPECIES_CORE_DIR}/pc_select_run.txt",
        f"{SPECIES_CORE_DIR}/pc_select_exp.txt"            
    shell:
        '''
        cd {WDIR}
        Rscript {WDIR}/scripts/2-Subsampling/x-72-select.R -s {SP_ECO}
        Rscript {WDIR}/scripts/2-Subsampling/x-72-select.R -s {SP_CORE}
        '''

rule formatting:
    input:
        f"{SPECIES_CORE_DIR}/pc_select_run.txt",
        f"{SPECIES_ECO_DIR}/pc_select_run.txt" 
    output:
        f"{SPECIES_ECO_DIR}/04.table.txt",
        f"{SPECIES_ECO_DIR}/04.url.txt",
        f"{SPECIES_CORE_DIR}/04.table.txt",
        f"{SPECIES_CORE_DIR}/04.url.txt"
    shell:
        '''
        cd {SPECIES_ECO_DIR}
        {WDIR}/scripts/2-Subsampling/x-73-formating.pl
        cd {SPECIES_CORE_DIR}
        {WDIR}/scripts/2-Subsampling/x-73-formating.pl
        '''

rule binary_expression:
    input:
        f"{SPECIES_DIR}/key",
        f"{SPECIES_DIR}/gc.d.ecotype/1.gc",
        f"{SPECIES_DIR}/gc.d.core/1.gc"
    params:
        ver