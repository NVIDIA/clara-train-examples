#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

my_dir="$(dirname "$(readlink -f "$0")")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"
additional_options="$*"

CONFIG_FILE=config/config_train_Unet.json
ENVIRONMENT_FILE=config/environment.json

INPUT_CKPT="${MMAR_ROOT}/models/config_train_Unet/model.pt"
OUTPUT_CKPT="${MMAR_ROOT}/models/config_train_Unet/model.ts"

python3 -u -m medl.apps.export \
    -m $MMAR_ROOT \
    -c $CONFIG_FILE \
    -e $ENVIRONMENT_FILE \
    --model_path "${INPUT_CKPT}" \
    --output_path "${OUTPUT_CKPT}" \
    --input_shape "[1, 1, 160, 160, 160]" \
    ${additional_options}
