from datetime import datetime

WDIR = "/home/daffa/Work/2025/11-ATTED-II_ver-13.0"
cutSP = config['species_id']
TAXONOMY_ID = config['taxonomy_id']

REP_NO = f"_{config.get('repetition_id', '')}" if config.get('repetition_id', '') else ""

# SP is for: SPECIES_ID + type (RNA, microarray, etc.)
SP = f"{cutSP}-r{REP_NO}"
SPECIES_DIR = f"{WDIR}/{SP}"

# step specific parameters
PCA_TYPE = "double"
SUBAGGING_AVE = config.get('subagging_ave', '') if config.get('subagging_ave', '') else 1000
VALID_NUM = config.get('valid_num', '') if config.get('valid_num', '') else 1000
SAMPLING_RATE = config.get('sampling_rate', '') if config.get('sampling_rate', '') else 50
KEGG_ftp_date = "2025-12-15"
EVAL_DATE = datetime.now().strftime('%Y-%m-%d')
EVAL_OUTPUT = f"{SPECIES_DIR}/score.KEGG50.KEGG.{KEGG_ftp_date}.{SP}.{EVAL_DATE}"


rule all:
    input:
        f"{SPECIES_DIR}/key_pair",
        f"{SPECIES_DIR}/subagging.logitMR.ave_{SUBAGGING_AVE}",
        f"{SPECIES_DIR}/nlmr.d",
        EVAL_OUTPUT,
        f"{SPECIES_DIR}/id-id-title.txt",
        f"{SPECIES_DIR}/study_info.txt",
        f"{SPECIES_DIR}/run_info.txt",
        f"{SPECIES_DIR}/pc_select_run.txt",
        f"{SPECIES_DIR}/pc_select_exp.txt",    
        f"{SPECIES_DIR}/pca_loadings.txt",
        f"{SPECIES_DIR}/04.table.txt",
        f"{SPECIES_DIR}/04.url.txt"

rule combat_pca:
    params:
        pca = PCA_TYPE
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
        Rscript {WDIR}/scripts/2-Subsampling/x-43-ComBat.RNA-seq.SGI2EGI.R -s {SP} -p {params.pca}
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
    params:
        subagging = SUBAGGING_AVE,
        valid_num = VALID_NUM,
        sampling_rate = SAMPLING_RATE
    input:
        f"{SPECIES_DIR}/.binary_expression_marker",
    output:
        protected(f"{SPECIES_DIR}/subagging.logitMR.ave_{SUBAGGING_AVE}")
    shell:
        '''
        cd {SPECIES_DIR}
        {WDIR}/scripts/2-Subsampling/x-45-coex_subagging_unsigned_int.pl -e -i paste.*.combat_pca.bin -o subagging -n {params.subagging} -s {params.sampling_rate} -v {params.valid_num} -c
        '''

rule z_scoring:
    input:
        key_pair = f"{SPECIES_DIR}/key_pair",
        coex_file = f"{SPECIES_DIR}/subagging.logitMR.ave_{SUBAGGING_AVE}"
    output:
        directory(f"{SPECIES_DIR}/nlmr.d"),
        directory(f"{SPECIES_DIR}/nlmr.d.beforezscore")
    shell:
        '''
        cd {SPECIES_DIR}
        mkdir {SPECIES_DIR}/tmp.nlmr_unsorted
        cd {SPECIES_DIR}/tmp.nlmr_unsorted
        paste {input.key_pair} {input.coex_file} | perl -lane '$mr{{$F[0]}}{{$F[1]}}=$F[2]; $mr{{$F[1]}}{{$F[0]}}=$F[2]; if ($. % 100000000 == 0){{for $g1 (keys %mr){{open OUT, ">>$g1"; for $g2 (keys %{{$mr{{$g1}}}}){{print OUT $g2,"\t",$mr{{$g1}}{{$g2}}}}}}; undef %mr}}; END{{for $g1 (keys %mr){{open OUT, ">>$g1"; for $g2 (keys %{{$mr{{$g1}}}}){{print OUT $g2,"\t",$mr{{$g1}}{{$g2}}}}}}}}'  
        mkdir {SPECIES_DIR}/nlmr.d
        for i in *; do
            perl -lane '$mr{{$F[0]}}=-$F[1]; END{{printf "%s\t%.2f\n", $ARGV, -log(1/$.)/log(2); for $g (sort {{$mr{{$b}}<=>$mr{{$a}}}} keys %mr){{printf "%s\t%.2f\n", $g, $mr{{$g}}}}}}' $i | uniq > ../nlmr.d/$i;
        done
        cd {SPECIES_DIR}
        rm -r {SPECIES_DIR}/tmp.nlmr_unsorted
        echo "transform finished, then z-scoring..."
        date
        {WDIR}/scripts/3-z-scoring/x-47-zscoring_directory.pl -i nlmr.d
        echo "Finished for {SP} >> {SP}/nlmrd.z."
        date
        echo "rename zscored directory to nlmr.d for preparation of upload..."
        mv {SPECIES_DIR}/nlmr.d {SPECIES_DIR}/nlmr.d.beforezscore
        mv {SPECIES_DIR}/nlmr.d.zscore {SPECIES_DIR}/nlmr.d
        '''

rule evaluation:
    input:
        key_pair = f"{SPECIES_DIR}/key_pair",
        coex_file = f"{SPECIES_DIR}/subagging.logitMR.ave_{SUBAGGING_AVE}"
    params:
        kegg_date = KEGG_ftp_date,
        cutSP = cutSP
    output:
        EVAL_OUTPUT
    shell:
        '''
        cd {SPECIES_DIR}
        {WDIR}/Eval/score_excl_paralog_pair.pl -s {params.cutSP} -K {WDIR}/Eval/KEGG.{params.kegg_date}/KEGG50 -g {WDIR}/Eval/ko-genes.{params.kegg_date}/{params.cutSP} -f {input.coex_file} -p {input.key_pair} -o {output} || true
        '''

# rule clean
rule clean:
    shell:
        '''
        rm -rf {SPECIES_DIR}/.binary_expression_marker {SPECIES_DIR}/*.txt {SPECIES_DIR}/key* {SPECIES_DIR}/paste.* {SPECIES_DIR}/gc.d {SPECIES_DIR}/nlmr.d {SPECIES_DIR}/79m*
        '''