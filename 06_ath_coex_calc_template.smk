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
LOG_DATETIME = datetime.now().strftime('%Y%m%d_%H%M%S')
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
        EVAL_CORE_OUTPUT,
        f"{SPECIES_ECO_DIR}/id-id-title.txt",
        f"{SPECIES_CORE_DIR}/id-id-title.txt",
        f"{SPECIES_ECO_DIR}/study_info.txt",
        f"{SPECIES_ECO_DIR}/run_info.txt",
        f"{SPECIES_CORE_DIR}/study_info.txt",
        f"{SPECIES_CORE_DIR}/run_info.txt",
        f"{SPECIES_ECO_DIR}/pc_select_run.txt",
        f"{SPECIES_CORE_DIR}/pc_select_exp.txt",    
        f"{SPECIES_ECO_DIR}/pca_loadings.txt",
        f"{SPECIES_CORE_DIR}/pca_loadings.txt",
        f"{SPECIES_ECO_DIR}/04.table.txt",
        f"{SPECIES_ECO_DIR}/04.url.txt", 
        f"{SPECIES_CORE_DIR}/04.table.txt", 
        f"{SPECIES_CORE_DIR}/04.url.txt"

rule attrib_info:
    output:
        f"{SPECIES_DIR}/ecotype.study"
    log:
        f"{SPECIES_DIR}/logs/attrib_info.{LOG_DATETIME}.log"
    shell:
        '''
        exec > {log} 2>&1
        python3 {WDIR}/scripts/1-PreSubsampling/x01-create-attrib-info0.py --taxonomy_id {TAXONOMY_ID}
        echo "SRP279357\t\t1664\t\"male parent, female parent\"" >> {SPECIES_DIR}/ecotype.study
        echo "SRP2793571664male parent, female parent, added to ecotype.study."
        '''

rule combat_pca:
    params:
        pca = PCA_TYPE
    input:
        f"{WDIR}/refseq/{cutSP}-r_SpeciesSpecific2EGI",
        f"{WDIR}/blacklist-run",
        f"{WDIR}/srainfo-study_table.txt",
        f"{SPECIES_DIR}/ecotype.study"
    output:
        f"{SPECIES_DIR}/list_ecotype.txt",
        f"{SPECIES_DIR}/list_core.txt",
        f"{SPECIES_DIR}/key",
        f"{SPECIES_DIR}/gc.d.ecotype/1.gc",
        f"{SPECIES_DIR}/gc.d.core/1.gc",
        f"{SPECIES_DIR}/paste.expression.combat",
        f"{SPECIES_DIR}/pca_loadings_ecotype.txt",
        f"{SPECIES_DIR}/pca_loadings_core.txt"
    log:
        f"{SPECIES_DIR}/logs/combat_pca.{LOG_DATETIME}.log"
    shell:
        '''
        cd {WDIR}
        Rscript {WDIR}/scripts/2-Subsampling/x-43-ComBat.RNA-seq.ecotype.R -s {SP} -p {params.pca} > {log} 2>&1
        '''

rule loading_annotation_prep:
    input:
        f"{SPECIES_DIR}/list_ecotype.txt",
        f"{SPECIES_DIR}/list_core.txt",
        f"{SPECIES_DIR}/pca_loadings_ecotype.txt",
        f"{SPECIES_DIR}/pca_loadings_core.txt"
    output:
        f"{SPECIES_CORE_DIR}/list.txt",
        f"{SPECIES_ECO_DIR}/list.txt",
        f"{SPECIES_CORE_DIR}/pca_loadings.txt",
        f"{SPECIES_ECO_DIR}/pca_loadings.txt"
    log:
        f"{SPECIES_DIR}/logs/loading_annotation_prep.{LOG_DATETIME}.log"
    shell:
        '''
        exec > {log} 2>&1
        echo "loading annotation for Core"
        cd {SPECIES_CORE_DIR}
        ln -s {SPECIES_DIR}/pca_loadings_core.txt pca_loadings.txt
        ln -s {SPECIES_DIR}/list_core.txt list.txt
        echo "loading annotation for Ecotype"
        cd {SPECIES_ECO_DIR}
        ln -s {SPECIES_DIR}/pca_loadings_ecotype.txt pca_loadings.txt
        ln -s {SPECIES_DIR}/list_ecotype.txt list.txt
        '''

rule create_id_title:
    input:
        f"{SPECIES_CORE_DIR}/list.txt",
        f"{SPECIES_ECO_DIR}/list.txt",
        f"{WDIR}/srainfo.sqlite3"
    output:
        f"{SPECIES_CORE_DIR}/id-id-title.txt",
        f"{SPECIES_ECO_DIR}/id-id-title.txt"
    log:
        f"{SPECIES_DIR}/logs/create_id_title.{LOG_DATETIME}.log"
    shell:
        '''
        cd {WDIR}
        python3 {WDIR}/scripts/1-PreSubsampling/x-61-create-id-id-title.py --sp {SP_ECO} > {log} 2>&1
        python3 {WDIR}/scripts/1-PreSubsampling/x-61-create-id-id-title.py --sp {SP_CORE} >> {log} 2>&1
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
    log:
        f"{SPECIES_DIR}/logs/create_info.{LOG_DATETIME}.log"
    shell:
        '''
        cd {WDIR}
        python3 {WDIR}/scripts/1-PreSubsampling/x-62-info-txt.py --sp {SP_CORE} > {log} 2>&1
        python3 {WDIR}/scripts/1-PreSubsampling/x-62-info-txt.py --sp {SP_ECO} >> {log} 2>&1
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
    log:
        f"{SPECIES_DIR}/logs/selecting.{LOG_DATETIME}.log"
    shell:
        '''
        cd {WDIR}
        Rscript {WDIR}/scripts/2-Subsampling/x-72-select.R -s {SP_ECO} > {log} 2>&1
        Rscript {WDIR}/scripts/2-Subsampling/x-72-select.R -s {SP_CORE} >> {log} 2>&1
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
    log:
        f"{SPECIES_DIR}/logs/formatting.{LOG_DATETIME}.log"
    shell:
        '''
        cd {SPECIES_ECO_DIR}
        {WDIR}/scripts/2-Subsampling/x-73-formating.pl > {log} 2>&1
        cd {SPECIES_CORE_DIR}
        {WDIR}/scripts/2-Subsampling/x-73-formating.pl >> {log} 2>&1
        '''

rule binary_expression:
    input:
        f"{SPECIES_DIR}/key",
        f"{SPECIES_DIR}/gc.d.ecotype/1.gc",
        f"{SPECIES_DIR}/gc.d.core/1.gc"
    params:
        version = datetime.now().strftime("%y.%m")
    output:
        temp(f"{SPECIES_DIR}/.binary_expression_marker")
    log:
        f"{SPECIES_DIR}/logs/binary_expression.{LOG_DATETIME}.log"
    shell:
        '''
        cd {WDIR}
        {WDIR}/scripts/2-Subsampling/x-44-paste_gc_data.pl -s {SP} -v {params.version} -d gc.d.ecotype -m combat_pca.ecotype > {log} 2>&1
        {WDIR}/scripts/2-Subsampling/x-44-paste_gc_data.pl -s {SP} -v {params.version} -d gc.d.core -m combat_pca.core >> {log} 2>&1
        touch {output}
        '''

rule key_pair:
    input:
        f"{SPECIES_DIR}/.binary_expression_marker"
    output:
        f"{SPECIES_DIR}/key_pair"
    log:
        f"{SPECIES_DIR}/logs/key_pair.{LOG_DATETIME}.log"
    shell:
        '''
        cd {SPECIES_DIR}
        perl -lne 'chomp; push @k,$_ if $_=~/\w/; END{{for $i (0..$#k-1){{for $j ($i+1..$#k){{print "$k[$i]\t$k[$j]"}}}}}}' paste.*.core.probe > {output} 2> {log}
        '''

rule subagging_coexpression:
    params:
        subagging = SUBAGGING_AVE,
        valid_num = VALID_NUM,
        sampling_rate = SAMPLING_RATE
    input:
        f"{SPECIES_DIR}/.binary_expression_marker"
    output:
        protected(f"{SPECIES_DIR}/subagging.ecotype.logitMR.ave_{SUBAGGING_AVE}"),
        protected(f"{SPECIES_DIR}/subagging.core.logitMR.ave_{SUBAGGING_AVE}")
    log:
        f"{SPECIES_DIR}/logs/subagging_coexpression.{LOG_DATETIME}.log"
    shell:
        '''
        cd {SPECIES_DIR}
        {WDIR}/scripts/2-Subsampling/x-45-coex_subagging_unsigned_int.pl -e -i paste.*.combat_pca.ecotype.bin -o subagging.ecotype -n {params.subagging} -s {params.sampling_rate} -v {params.valid_num} -c > {log} 2>&1
        {WDIR}/scripts/2-Subsampling/x-45-coex_subagging_unsigned_int.pl -e -i paste.*.combat_pca.core.bin -o subagging.core -n {params.subagging} -s {params.sampling_rate} -v {params.valid_num} -c >> {log} 2>&1
        '''

rule z_scoring:
    input:
        key_pair = f"{SPECIES_DIR}/key_pair",
        coex_file_ecotype = f"{SPECIES_DIR}/subagging.ecotype.logitMR.ave_{SUBAGGING_AVE}",
        coex_file_core = f"{SPECIES_DIR}/subagging.core.logitMR.ave_{SUBAGGING_AVE}"
    output:
        directory(f"{SPECIES_DIR}/nlmr.d.ecotype"),
        directory(f"{SPECIES_DIR}/nlmr.d.ecotype.beforezscore"),
        directory(f"{SPECIES_DIR}/nlmr.d.core"),
        directory(f"{SPECIES_DIR}/nlmr.d.core.beforezscore")
    log:
        f"{SPECIES_DIR}/logs/z_scoring.{LOG_DATETIME}.log"
    shell:
        '''
        exec > {log} 2>&1
        echo "(5) Transform to table format, then z-scoring... (ecotype part)"
        cd {SPECIES_DIR}
        mkdir -p {SPECIES_DIR}/tmp.nlmr_unsorted.ecotype
        cd {SPECIES_DIR}/tmp.nlmr_unsorted.ecotype
        paste {input.key_pair} {input.coex_file_ecotype} | perl -lane '$mr{{$F[0]}}{{$F[1]}}=$F[2]; $mr{{$F[1]}}{{$F[0]}}=$F[2]; if ($. % 100000000 == 0){{for $g1 (keys %mr){{open OUT, ">>$g1"; for $g2 (keys %{{$mr{{$g1}}}}){{print OUT $g2,"\t",$mr{{$g1}}{{$g2}}}}}}; undef %mr}}; END{{for $g1 (keys %mr){{open OUT, ">>$g1"; for $g2 (keys %{{$mr{{$g1}}}}){{print OUT $g2,"\t",$mr{{$g1}}{{$g2}}}}}}}}'  
        mkdir -p {SPECIES_DIR}/nlmr.d.ecotype
        for i in *; do
            perl -lane '$mr{{$F[0]}}=-$F[1]; END{{printf "%s\t%.2f\n", $ARGV, -log(1/$.)/log(2); for $g (sort {{$mr{{$b}}<=>$mr{{$a}}}} keys %mr){{printf "%s\t%.2f\n", $g, $mr{{$g}}}}}}' $i | uniq > ../nlmr.d.ecotype/$i;
        done
        cd {SPECIES_DIR}
        rm -r {SPECIES_DIR}/tmp.nlmr_unsorted.ecotype
        echo "transform finished, then z-scoring..."
        date
        {WDIR}/scripts/3-z-scoring/x-47-zscoring_directory.pl -i nlmr.d.ecotype
        echo "Finished for {SP} >> {SP}/nlmrd.z."
        date
        echo "rename zscored directory to nlmr.d for preparation of upload..."
        mv {SPECIES_DIR}/nlmr.d.ecotype {SPECIES_DIR}/nlmr.d.ecotype.beforezscore
        mv {SPECIES_DIR}/nlmr.d.ecotype.zscore {SPECIES_DIR}/nlmr.d.ecotype
        echo "(5) Transform to table format, then z-scoring... (core part)"
        cd {SPECIES_DIR}
        mkdir -p {SPECIES_DIR}/tmp.nlmr_unsorted.core
        cd {SPECIES_DIR}/tmp.nlmr_unsorted.core
        paste {input.key_pair} {input.coex_file_core} | perl -lane '$mr{{$F[0]}}{{$F[1]}}=$F[2]; $mr{{$F[1]}}{{$F[0]}}=$F[2]; if ($. % 100000000 == 0){{for $g1 (keys %mr){{open OUT, ">>$g1"; for $g2 (keys %{{$mr{{$g1}}}}){{print OUT $g2,"\t",$mr{{$g1}}{{$g2}}}}}}; undef %mr}}; END{{for $g1 (keys %mr){{open OUT, ">>$g1"; for $g2 (keys %{{$mr{{$g1}}}}){{print OUT $g2,"\t",$mr{{$g1}}{{$g2}}}}}}}}'  
        mkdir -p {SPECIES_DIR}/nlmr.d.core
        for i in *; do
            perl -lane '$mr{{$F[0]}}=-$F[1]; END{{printf "%s\t%.2f\n", $ARGV, -log(1/$.)/log(2); for $g (sort {{$mr{{$b}}<=>$mr{{$a}}}} keys %mr){{printf "%s\t%.2f\n", $g, $mr{{$g}}}}}}' $i | uniq > ../nlmr.d.core/$i;
        done
        cd {SPECIES_DIR}
        rm -r {SPECIES_DIR}/tmp.nlmr_unsorted.core
        echo "transform finished, then z-scoring..."
        date
        {WDIR}/scripts/3-z-scoring/x-47-zscoring_directory.pl -i nlmr.d.core
        echo "Finished for {SP} >> {SP}/nlmrd.z."
        date
        echo "rename zscored directory to nlmr.d for preparation of upload..."
        mv {SPECIES_DIR}/nlmr.d.core {SPECIES_DIR}/nlmr.d.core.beforezscore
        mv {SPECIES_DIR}/nlmr.d.core.zscore {SPECIES_DIR}/nlmr.d.core
        '''

rule evaluation:
    input:
        key_pair = f"{SPECIES_DIR}/key_pair",
        coex_file_ecotype = f"{SPECIES_DIR}/subagging.ecotype.logitMR.ave_{SUBAGGING_AVE}",
        coex_file_core = f"{SPECIES_DIR}/subagging.core.logitMR.ave_{SUBAGGING_AVE}"
    params:
        kegg_date = KEGG_ftp_date,
        cutSP = cutSP
    output:
        output_ecotype = EVAL_ECOTYPE_OUTPUT,
        output_core = EVAL_CORE_OUTPUT
    log:
        f"{SPECIES_DIR}/logs/evaluation.{LOG_DATETIME}.log"
    shell:
        '''
        cd {SPECIES_DIR}
        {WDIR}/Eval/score_excl_paralog_pair.pl -s {params.cutSP} -K {WDIR}/Eval/KEGG.{params.kegg_date}/KEGG50 -g {WDIR}/Eval/ko-genes.{params.kegg_date}/{params.cutSP} -f {input.coex_file_ecotype} -p {input.key_pair} -o {output.output_ecotype} > {log} 2>&1 || true
        {WDIR}/Eval/score_excl_paralog_pair.pl -s {params.cutSP} -K {WDIR}/Eval/KEGG.{params.kegg_date}/KEGG50 -g {WDIR}/Eval/ko-genes.{params.kegg_date}/{params.cutSP} -f {input.coex_file_core} -p {input.key_pair} -o {output.output_core} >> {log} 2>&1 || true
        '''