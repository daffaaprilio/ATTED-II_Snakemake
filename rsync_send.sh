#!/bin/zsh
TAXID=$1

DESTINATION_ATTED_DIR=azureuser@azure:/mnt/azureuser/Work/2025/11-ATTED-II_ver_13.0

SOURCE_ATTED_DIR=/home/daffa/Work/2025/11-ATTED-II_ver-13.0
FILES_TO_COPY=(
    "./output/${TAXID}"
)

for file in ${FILES_TO_COPY[@]}; do
    rsync -avzP --partial --inplace --compress-level=6 --relative -e ssh ${SOURCE_ATTED_DIR}/${file} ${DESTINATION_ATTED_DIR}/;
done