#!/bin/zsh

DESTINATION_ATTED_DIR=/home/daffa/Work/2025/11-ATTED-II_ver-13.0

SOURCE_ATTED_DIR=azureuser@azure:/data/azureuser/Work/2025/11-ATTED-II_ver_13.0
FILES_TO_COPY=(
    "./output/39946"
)

for file in ${FILES_TO_COPY[@]}; do
    rsync -avzP --partial --inplace --compress-level=6 --relative -e ssh ${SOURCE_ATTED_DIR}/${file} ${DESTINATION_ATTED_DIR}/;
done