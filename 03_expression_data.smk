import os
import glob
import datetime
from pathlib import Path

WDIR = config['wdir']
SPECIES_ID = config['species_id']
TAXONOMY_ID = config['taxonomy_id']
TAXONOMY_ID_LIST_FILE = f'{WDIR}/list/{TAXONOMY_ID}-list.txt'

DATE = datetime.datetime.now().strftime('%Y%m%d')

# Parse the list file at the top level
ACC_IDS = []
URLS = []

if os.path.exists(TAXONOMY_ID_LIST_FILE):
    with open(TAXONOMY_ID_LIST_FILE, 'r') as f:
        for line in f:
            line = line.strip()
            if line:
                # full ftp link
                url = line
                # parse link 
                parts = line.split("/")
                sra_file = parts[-1]
                # accession id
                acc_id = sra_file.replace('.sra', '')
                # appending to each list
                ACC_IDS.append(acc_id)
                URLS.append(url)

# Create mapping from accession id to url
ACC_ID_TO_URL = {acc_id: url for acc_id, url in zip(ACC_IDS, URLS)}

rule all:
    input:
        expand("output/{acc_id}.txt", acc_id = ACC_IDS)

rule curl:
    output:
        "sra/{acc_id}.sra"
    params:
        url = lambda wildcards: ACC_ID_TO_URL[wildcards.acc_id]
    log:
        f"logs/{TAXONOMY_ID}/curl/{{acc_id}}_{DATE}.log"
    shell:
        '''
        curl -o {output} {params.url} 2> {log}
        '''

# in the case of paired end
rule fastq_dump_PE:
    input:
        "sra/{acc_id}.sra"
    output:
        read1 = "fastq/{acc_id}_1.fastq",
        read2 = "fastq/{acc_id}_2.fastq",
        read3 = "fastq/{acc_id}.fastq" # if not all acc_id outputs this third file, stop using --split-3 option (https://www.biostars.org/p/156909/)
    log:
        f"logs/fastq_dump/{TAXONOMY_ID}/{{acc_id}}_{DATE}.log"
    shell:
        '''
        fastq-dump -L 5 -W -M 50 --skip-technical --split-3 --qual-filter-1 --split-files -O fastq {input} 2> {log}
        '''
rule trimmomatic_PE:
    input:
        read1 = "fastq/{acc_id}_1.fastq",
        read2 = "fastq/{acc_id}_2.fastq"
    output:
        paired1 = "fastq/{acc_id}_1_paired.fastq",
        paired2 = "fastq/{acc_id}_2_paired.fastq",
        unpaired1 = "fastq/{acc_id}_1_unpaired.fastq",
        unpaired2 = "fastq/{acc_id}_2_unpaired.fastq"
    log:
        f"logs/trimmomatic/{TAXONOMY_ID}/{{acc_id}}_{DATE}.log"
    shell:
        '''
        java -jar trimmomatic-0.39.jar PE -phred33 {input.read1} {input.read2} {output.paired1} {output.paired2} {output.unpaired1} {output.unpaired2} SLIDINGWINDOW:4:15 MINLEN:36 2> {log}
        '''

rule bowtie2_PE:
    input: 
        trimmed1 = "fastq/{acc_id}_1_paired.fastq",
        trimmed2 = "fastq/{acc_id}_2_paired.fastq",
        index = expand(f"index/{TAXONOMY_ID}.{{ext}}.bt2", ext=["1", "2", "3", "4", "rev.1", "rev.2"])
    output:
        "sam/{acc_id}.sam"
    log:
        f"logs/bowtie2/{TAXONOMY_ID}/{{acc_id}}_{DATE}.log"
    shell:
        '''
        bowtie2 -x {input.index} --very-sensitive -k 5 -S {output} -U {input.trimmed1} {input.trimmed2} 2> {log}
        '''

# in the case of single end
rule fastq_dump_SE:
    input:
        "sra/{acc_id}.sra"
    output:
        read = "fastq/{acc_id}.fastq"
    log:
        f"logs/fastq_dump/{TAXONOMY_ID}/{{acc_id}}_{DATE}.log"
    shell:
        '''
        fastq-dump -L 5 -W -M 50 --skip-technical --split-3 --qual-filter-1 --split-files -O fastq {input} 2> {log}
        '''
    
rule trimmomatic_SE:
    input:
        "fastq/{acc_id}.fastq"
    output:
        "fastq/{acc_id}_trimmed.fastq"
    log:
        f"logs/trimmomatic/{TAXONOMY_ID}/{{acc_id}}_{DATE}.log"
    shell:
        '''
        java -jar trimmomatic-0.39.jar SE -phred33 {input} {output} SLIDINGWINDOW:4:15 MINLEN:36 2> {log}
        '''

rule bowtie2_SE:
    input: 
        trimmed = "fastq/{acc_id}_trimmed.fastq",
        index = expand(f"index/{TAXONOMY_ID}.{{ext}}.bt2", ext=["1", "2", "3", "4", "rev.1", "rev.2"])
    output:
        "sam/{acc_id}.sam"
    log:
        f"logs/bowtie2/{TAXONOMY_ID}/{{acc_id}}_{DATE}.log"
    shell:
        '''
        bowtie2 -x {input.index} --very-sensitive -k 5 -S {output} -U {input.trimmed} 2> {log}
        '''

# feature count
rule featurecount:
    input:
        sam = "sam/{acc_id}.sam",
        annotation = f"refseq/{SPECIES_ID}_annotation"
    output:
        "output/{acc_id}.txt"
    log:
        f"logs/featureCount{TAXONOMY_ID}/{{acc_id}}_{DATE}.log"
    shell:
        '''
        featureCounts -t gene -g gene_id -a {input.annotation} -o {output} {input.sam} 2> {log}
        '''

rule clean:
    shell:
        '''
        rm -rf sra/ logs/ fastq/ sam/ output/
        '''

