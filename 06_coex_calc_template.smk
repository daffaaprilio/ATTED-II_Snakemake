from datetime import datetime

WDIR = "/home/daffa/Work/2025/11-ATTED-II_ver-13.0"
cutSP = config['species_id']
TAXONOMY_ID = config['taxonomy_id']

# SP is for: SPECIES_ID + type (RNA, microarray, etc.)
SP = f"{cutSP}-r"
SPECIES_DIR = f"{WDIR}/{SP}"

rule all:
    input:
        f"{SPECIES_DIR}/key_pair",
        f"{SPECIES_DIR}/subagging.logitMR.ave_1000"

rule combat_pca:
    params:
        max_gene_no = 65000
    input:
        f"{WDIR}/refseq/{cutSP}-r_SpeciesSpecific2EGI",
        f"{WDIR}/blacklist-run",
        f"{WDIR}/srainfo-study_table.txt"
    output:
        f"{SPECIES_DIR}/list.txt",
        f"{SPECIES_DIR}/key",
        f"{SPECIES_DIR}/gc.d/1.gc",
        f"{SPECIES_DIR}/paste.expression.combat",
        f"{SPECIES_DIR}/pca_loadings.txt"
    shell:
        '''
        cd {WDIR}
        Rscript {WDIR}/scripts/2-Subsampling/x-43-ComBat.RNA-seq.SGI2EGI.R -s {SP} -n {params.max_gene_no}
        '''

rule create_id_title:
    input:
        f"{SPECIES_DIR}/list.txt",
        f"{WDIR}/srainfo.sqlite3"
    output:
        f"{SPECIES_DIR}/id-id-title.txt"
    shell:
        '''
        cd {WDIR}
        python3 {WDIR}/scripts/1-PreSubsampling/x-61-create-id-id-title.py --sp {SP}
        '''

rule create_info:
    input:
        f"{SPECIES_DIR}/list.txt",
        f"{WDIR}/srainfo.sqlite3"
    output:
        f"{SPECIES_DIR}/study_info.txt",
        f"{SPECIES_DIR}/run_info.txt"
    shell:
        '''
        cd {WDIR}
        python3 {WDIR}/scripts/1-PreSubsampling/x-62-info-txt.py --sp {SP}
        '''

rule selecting:
    input:
        f"{SPECIES_DIR}/pca_loadings.txt",
        f"{SPECIES_DIR}/study_info.txt",
        f"{SPECIES_DIR}/run_info.txt"
    output:
        f"{SPECIES_DIR}/pc_select_run.txt",
        f"{SPECIES_DIR}/pc_select_exp.txt"        
    shell:
        '''
        cd {WDIR}
        Rscript {WDIR}/scripts/2-Subsampling/x-72-select.R -s {SP}
        '''

rule formatting:
    input:
        f"{SPECIES_DIR}/pc_select_run.txt"
    output:
        f"{SPECIES_DIR}/04.table.txt",
        f"{SPECIES_DIR}/04.url.txt"
    shell:
        '''
        cd {SPECIES_DIR}
        {WDIR}/scripts/2-Subsampling/x-73-formating.pl
        '''

rule binary_expression:
    input:
        f"{SPECIES_DIR}/key",
        f"{SPECIES_DIR}/gc.d/1.gc"
    params:
        version = datetime.now().strftime("%y.%m")
    output:
        temp(f"{SPECIES_DIR}/.binary_expression_marker")
    shell:
        '''
        cd {WDIR}
        {WDIR}/scripts/2-Subsampling/x-44-paste_gc_data.pl -s {SP} -v {params.version} -d gc.d -m combat_pca
        touch {output}
        '''

rule key_pair:
    input:
        f"{SPECIES_DIR}/.binary_expression_marker"
    output:
        f"{SPECIES_DIR}/key_pair"
    shell:
        '''
        cd {SPECIES_DIR}
        perl -lne 'chomp; push @k,$_ if $_=~/\w/; END{{for $i (0..$#k-1){{for $j ($i+1..$#k){{print "$k[$i]\t$k[$j]"}}}}}}' paste.*.combat_pca.probe > {output}
        '''

rule subagging_coexpression:
    input:
        f"{SPECIES_DIR}/.binary_expression_marker",
    output:
        f"{SPECIES_DIR}/subagging.logitMR.ave_1000"
    shell:
        '''
        cd {SPECIES_DIR}
        {WDIR}/scripts/2-Subsampling/x-45-coex_subagging_unsigned_int.pl -e -i paste.*.combat_pca.bin -o subagging -n 1000 -s 50 -v 1000
        '''

# rule clean
rule clean:
    shell:
        '''
        rm -rf {SPECIES_DIR}/*.txt {SPECIES_DIR}/key* {SPECIES_DIR}/paste.* {SPECIES_DIR}/gc.d
        '''