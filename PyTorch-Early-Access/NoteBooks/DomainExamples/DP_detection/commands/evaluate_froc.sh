#!/usr/bin/env bash

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"

GT_FOLDER_PATH=/workspace/ground_truths
CSV_FOLDER_PATH=${MMAR_ROOT}/eval

python3 ${MMAR_ROOT}/custom/froc.py $GT_FOLDER_PATH $CSV_FOLDER_PATH