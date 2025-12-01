#!/bin/zsh

# on cosmo from matsu, okadama, tane

DESTINATION_ATTED_DIR=/home/daffa/Work/2025/11-ATTED-II_ver-13.0

# SOURCE_ATTED_DIR_MATSU=daffa@matsu:/home/daffa/Work/2025/11-ATTED-II_ver-13.0
# FILES_TO_COPY_MATSU=(
#     "./output/3055"
#     "./output/39946"
#     "./output/4113"
# )

# for file in ${FILES_TO_COPY_MATSU[@]}; do
#     rsync -avzP --partial --inplace --compress-level=6 --relative -e ssh ${SOURCE_ATTED_DIR_MATSU}/${file} ${DESTINATION_ATTED_DIR}/;
# done

SOURCE_ATTED_DIR_OKADAMA=daffa@okadama:/home/daffa/Work/2025/11-ATTED-II_ver-13.0
FILES_TO_COPY_OKADAMA=(
    "./output/15368"
    # "./output/2711"
)

for file in ${FILES_TO_COPY_OKADAMA[@]}; do
    rsync -avzP --partial --inplace --compress-level=6 --relative -e ssh ${SOURCE_ATTED_DIR_OKADAMA}/${file} ${DESTINATION_ATTED_DIR}/;
done

SOURCE_ATTED_DIR_TANE=daffa@tane:/home/daffa/Work/2025/11-ATTED-II_ver-13.0
FILES_TO_COPY_TANE=(
    "./output/4097"
)

for file in ${FILES_TO_COPY_TANE[@]}; do
    rsync -avzP --partial --inplace --compress-level=6 --relative -e ssh ${SOURCE_ATTED_DIR_TANE}/${file} ${DESTINATION_ATTED_DIR}/;
done



