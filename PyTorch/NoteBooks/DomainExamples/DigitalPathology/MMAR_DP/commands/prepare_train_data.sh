#!/usr/bin/env bash

# needs ./coords and ./jsons from NCRF
# also https://github.com/baidu-research/NCRF/blob/master/wsi/data/annotation.py

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"

python3 ${MMAR_ROOT}/custom/create_list.py


