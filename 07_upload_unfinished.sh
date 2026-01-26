#!/bin/bash

UNFINISHED=(
    Ath-u.c5-0
    Ath-r.c7-0
    Ath-e.c2-0
    Gma-u.c5-0
)

for sp in "${UNFINISHED[@]}"; do
    mkdir -p upload/coex/${sp} upload/coex_unzip/${sp}
    echo "Currently under calculation" > upload/coex/${sp}/type
done