#!/bin/zsh
DESTINATION_ATTED_DIR=daffa@naha:/db/atted/datastock

SOURCE_ATTED_DIR=/home/daffa/Work/2025/11-ATTED-II_ver-13.0/upload/
FILES_TO_COPY=(
    "./coex"
)

for file in ${FILES_TO_COPY[@]}; do
    # ls ${SOURCE_ATTED_DIR}/${file}/*
    rsync -avzP --partial --inplace --compress-level=6 --relative -e ssh ${SOURCE_ATTED_DIR}/${file} ${DESTINATION_ATTED_DIR}/;
done