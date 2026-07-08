#------------------------------------------------------------
# Load configuration
configfile: 'config/data_preparation.yaml'
configfile: 'config/secrets.yaml'


SPECIES_LIST = config['species_id']
TAXID_LIST = config['taxonomy_id']
DOWNLOAD_REFGEN_DICT = config['download_refgen_dict']
DOWNLOAD_ANNOT_DICT = config['download_annot_dict']
WDIR = config['wdir']

#------------------------------------------------------------
# Helper function

# to extract filename from URL
def get_filename(url):
    return url.split('/')[-1].split('.gz')[0]

# to create a species-taxid key-value pair
SPECIES_TO_TAXID = dict(zip(SPECIES_LIST, TAXID_LIST))

#------------------------------------------------------------
# Global variables for file patterns
REFGEN_FILES = {species: get_filename(url) for species, url in DOWNLOAD_REFGEN_DICT.items()}
ANNOT_FILES = {species: get_filename(url) for species, url in DOWNLOAD_ANNOT_DICT.items()}

#------------------------------------------------------------
# Specifying directory path

REFSEQ_DIR = 'refseq'
INDEX_DIR = 'index'

#------------------------------------------------------------
# Specifying single file input

GENE_SEQ = REFSEQ_DIR + '/{species}_gene_seq'
ANNOTATION = REFSEQ_DIR + '/{species}_annotation'
EGI = REFSEQ_DIR + '/{species}-r_SpeciesSpecific2EGI'
INDEX = INDEX_DIR + '/{taxid}.done'

#------------------------------------------------------------
# Expanded file lists for all species and taxid
ALL_GENE_SEQ = expand(GENE_SEQ, species=SPECIES_LIST)
ALL_ANNOTATION = expand(ANNOTATION, species=SPECIES_LIST)
ALL_EGI = expand(EGI, species=SPECIES_LIST)
ALL_INDEX = expand(INDEX, taxid=TAXID_LIST)

#------------------------------------------------------------
# Rules

rule all:
    input:
        ALL_GENE_SEQ,
        ALL_ANNOTATION,
        ALL_EGI,
        ALL_INDEX

rule clean:
    shell: 
        'rm -rf {ALL_GENE_SEQ} {ALL_ANNOTATION} {ALL_EGI} {ALL_INDEX} {REFSEQ_DIR}/*.fna {REFSEQ_DIR}/*.gff {REFSEQ_DIR}/*.gz'

## Reference genome processing
rule process_reference_genome:
    params:
        download_link = lambda wildcards: DOWNLOAD_REFGEN_DICT[wildcards.species],
        filename = lambda wildcards: REFGEN_FILES[wildcards.species]
    output: 
        GENE_SEQ
    shell:
        '''
        wget -nc {params.download_link} -O {REFSEQ_DIR}/{params.filename}.gz
        gzip -dk {REFSEQ_DIR}/{params.filename}.gz
        cp {REFSEQ_DIR}/{params.filename} {output}
        '''

rule bowtie_index:
    input:
        lambda wildcards: f"{REFSEQ_DIR}/{[species for species, taxid in SPECIES_TO_TAXID.items() if str(taxid) == wildcards.taxid][0]}_gene_seq"
    output:
        # expand(INDEX_DIR + "/{{taxid}}.{ext}", ext=['1.bt2','2.bt2','3.bt2','4.bt2','rev.1.bt2','rev.2.bt2'])
        INDEX_DIR + "/{taxid}.done"
    shell:
        '''
        bowtie2-build -f {input} {INDEX_DIR}/{wildcards.taxid}
        touch {output}
        '''

## Annotation processing
rule process_annotation:
    params:
        download_link = lambda wildcards: DOWNLOAD_ANNOT_DICT[wildcards.species],
        filename = lambda wildcards: ANNOT_FILES[wildcards.species],
        modification = 's/ID=gene-/gene_id=/'
    output:
        ANNOTATION
    shell:
        '''
        wget -nc {params.download_link} -O {REFSEQ_DIR}/{params.filename}.gz
        gzip -dk {REFSEQ_DIR}/{params.filename}.gz
        sed -e "{params.modification}" {REFSEQ_DIR}/{params.filename} > {output}
        '''

rule derive_EGI_file:
    input:
        ANNOTATION
    params:
        awk_script = '''$3 == "gene" {
            if (match($9, /gene_id=([^;]+)/, sp_gene_id) && match($9, /GeneID:([0-9]+)/, EGI)) {
                current_line = sp_gene_id[1] "\t" EGI[1]
                if (current_line != previous_line) {
                    print current_line
                    previous_line = current_line
                }
            }
        }'''
    output: 
        EGI
    shell:
        '''
        awk '{params.awk_script}' {input} > {output}
        '''