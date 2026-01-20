#!/bin/bash
## 2026-01-14
## A wrapper script that wraps multiple Snakefiles
# Please note that this (wrapping Snakefiles with a Bash script)
# is not the best practice of Snakemake, better to find a 
# proper way in the next ATTED-II versions.

WDIR=/home/daffa/Work/2025/11-ATTED-II_ver-13.0

PUB_VER_RNA=(
    Bdi-r.c1-0
    Bna-r.c1-0
    Bra-r.c6-0
    Cit-r.c1-0
    Cre-r.c1-0
    Ghi-r.c1-0
    Gma-r.c7-0
    Mtr-r.c5-0
    Nta-r.c1-0
    Osa-r.c6-0
    # Osi-r.c1-0
    Osa-e.c1-0
    Ppo-r.c4-0
    Sbi-r.c1-0
    Sly-r.c6-0
    Sot-r.c1-0
    Tae-r.c2-0
    Vvi-r.c5-0
    Zma-r.c6-0
)

PUB_VER_UNION=(
    Mtr-u.c5-0
    Osa-u.c5-0
    Ppo-u.c5-0
    Sly-u.c5-0
    Vvi-u.c5-0
    Zma-u.c5-0
)

out_file="${WDIR}/upload/ATTED-II_newDataList_2026_01.tsv"

if [ ! -d "${WDIR}/upload" ] ; then
    mkdir -p "${WDIR}/upload"
fi

if [ ! -f "${out_file}" ] ; then
    touch "${out_file}"
fi

# run snakemake
printf '%s\n' "${PUB_VER_RNA[@]}" | xargs -P 17 -I {} snakemake -c 1 -s ${WDIR}/07_upload-r.smk --config 'public_version'={} 'out_file'=${out_file}
printf '%s\n' "${PUB_VER_UNION[@]}" | xargs -P 6 -I {} snakemake -c 1 -s ${WDIR}/07_upload-u.smk --config 'public_version'={} 'out_file'=${out_file}

# rename Osi-r into Osa-e
# if [ -d "upload" ] && [ ! -d "upload/coex/Osa-e.c1-0" ]; then
#   grep -rl "Osi-r" upload 2>/dev/null | xargs -r sed -i 's/Osi-r/Osa-e/g'
#   find upload -type f -name '*Osi-r*' -exec bash -c 'mv "$1" "${1//Osi-r/Osa-e}" 2>/dev/null || true' _ {} \;
#   find upload -depth -type d -name '*Osi-r*' -exec bash -c 'mv "$1" "${1//Osi-r/Osa-e}" 2>/dev/null || true' _ {} \;
# fi




