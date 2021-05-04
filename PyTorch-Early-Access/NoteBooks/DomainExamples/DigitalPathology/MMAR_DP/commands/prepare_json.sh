#!/usr/bin/env bash

# needs ./coords and ./jsons from NCRF
# also https://github.com/baidu-research/NCRF/blob/master/wsi/data/annotation.py

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

DataDirRoot="/claraDevDay/Data/DP_CAMELYON16/"

python3 ${MMAR_ROOT}/custom/generate_json.py \
    --json_temp ${MMAR_ROOT}/custom/template.json \
    --list_folder ${DataDirRoot}/LocLabel/ \
    --json_out ${DataDirRoot}/datalist.json
	   
