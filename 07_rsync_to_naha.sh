#!/bin/zsh

# DESTINATION_ATTED_DIR=daffa@naha:/db/atted/datastock/coex/Ath
# SOURCE_ATTED_DIR=/home/daffa/Work/2025/11-ATTED-II_ver-13.0/upload/coex/ATTED-II_newDataList_2026_01.tsv
# rsync -av --itemize-changes -e ssh ${SOURCE_ATTED_DIR} ${DESTINATION_ATTED_DIR}/ 

# # move backups in upload_prev_microarray/coex/ to upload/coex/
# mv /home/daffa/Work/2025/11-ATTED-II_ver-13.0/upload_prev_microarray/coex/ /home/daffa/Work/2025/11-ATTED-II_ver-13.0/upload/coex/

# # real rsync to naha
# SOURCE_ATTED_DIR=/home/daffa/Work/2025/11-ATTED-II_ver-13.0/upload
# FILES_TO_COPY=(
#     "./coex"
#     "./coex_unzip/"
# )

    # ls ${SOURCE_ATTED_DIR}/${file}/*
    # rsync -avzP --partial --inplace --compress-level=6 --relative -e ssh ${SOURCE_ATTED_DIR}/${file} ${DESTINATION_ATTED_DIR}/ --dry-run;
# rsync -azuP --itemize-changes -e ssh ${SOURCE_ATTED_DIR}/ ${DESTINATION_ATTED_DIR}/ --dry-run

# for file in ${FILES_TO_COPY[@]}; do
#     # ls ${SOURCE_ATTED_DIR}/${file}/*
#     # rsync -avzP --partial --inplace --compress-level=6 --relative -e ssh ${SOURCE_ATTED_DIR}/${file} ${DESTINATION_ATTED_DIR}/ --dry-run;
#     rsync -azuP --itemize-changes -e ssh ${SOURCE_ATTED_DIR}/ ${DESTINATION_ATTED_DIR}/ --dry-run;
# done

rsync -av -e ssh /home/daffa/Work/2025/11-ATTED-II_ver-13.0/upload/coex_unzip/Ath* daffa@naha:/db/atted/datastock/coex_unzip/