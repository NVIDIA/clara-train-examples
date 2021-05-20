#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

#clear
GPU2USE=$1
export CUDA_VISIBLE_DEVICES=$GPU2USE

echo "MMAR_ROOT set to $MMAR_ROOT"
additional_options="$*"

# Data list containing all data
CONFIG_FILE=config/config_train.json
ENVIRONMENT_FILE=config/environment.json

python3 -u -m medl.apps.train \
    -m $MMAR_ROOT \
    -c $CONFIG_FILE \
    -e $ENVIRONMENT_FILE \
    --write_train_stats \
    --set \
    print_conf=True \
    ${additional_options}
