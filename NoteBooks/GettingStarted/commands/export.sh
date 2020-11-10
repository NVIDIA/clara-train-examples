#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

CONFIG_FILE_NAME=trn_base.json

echo "MMAR_ROOT set to $MMAR_ROOT"

# Data list containing all data

CKPT_DIR=$MMAR_ROOT/models/${CONFIG_FILE_NAME::-5}

python3 -u -m nvmidl.apps.export \
    --model_file_format CKPT \
    --model_file_path $CKPT_DIR \
    --model_name model \
    --input_node_names "NV_MODEL_INPUT" \
    --output_node_names NV_MODEL_OUTPUT \
    --trt_min_seg_size 50 
