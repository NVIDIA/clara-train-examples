#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

set -f

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

additional_options="$*"

python3 -u -m deepgrow.prepare_dataset \
  --datalist_key "training" \
  --dimensions 2 \
  --limit 0 \
  --split 0.9 \
  --relative_path \
  ${additional_options}

#python3 -u -m deepgrow.prepare_dataset \
#  --dataset_root "/workspace/data/52432" \
#  --dataset_json "/workspace/data/52432/dataset.json" \
#  --datalist_key "training" \
#  --output "/workspace/data/52432/2D" \
#  --dimensions 2 \
#  --limit 0 \
#  --split 0.9 \
#  --relative_path \
#  ${additional_options}


: '
# Few Other Examples:
./prepare_dataset.sh --help

./prepare_dataset.sh \
  --dataset_root "/workspace/data/MSD_Task09_Spleen" \
  --dataset_json "/workspace/data/MSD_Task09_Spleen/dataset.json" \
  --datalist_key "training" \
  --output "/workspace/data/deepgrow/2D/spleen_min" \
  --limit 1
'
