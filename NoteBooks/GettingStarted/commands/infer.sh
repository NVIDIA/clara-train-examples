#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"

# Data list containing all data
CONFIG_FILE=config/config_validation_chpt.json
ENVIRONMENT_FILE=config/environment.json
MMAR_CKPT_DIR=$MMAR_ROOT/models/trn_base

python -u  -m nvmidl.apps.evaluate \
    -m $MMAR_ROOT \
    -c $CONFIG_FILE \
    -e $ENVIRONMENT_FILE \
    --set \
    output_infer_result=true \
    do_validation=false \
    MMAR_CKPT_DIR=$MMAR_CKPT_DIR
