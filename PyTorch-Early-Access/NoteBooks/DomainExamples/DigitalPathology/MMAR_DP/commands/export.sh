#!/usr/bin/env bash

my_dir="$(dirname "$(readlink -f "$0")")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"
additional_options="$*"

CONFIG_FILE=config/config_train.json
ENVIRONMENT_FILE=config/environment.json

INPUT_CKPT="${MMAR_ROOT}/models/model.pt"
OUTPUT_CKPT="${MMAR_ROOT}/models/model.ts"

python3 -u -m medl.apps.export \
    -m $MMAR_ROOT \
    -c $CONFIG_FILE \
    -e $ENVIRONMENT_FILE \
    --model_path "${INPUT_CKPT}" \
    --output_path "${OUTPUT_CKPT}" \
    --input_shape "[1, 3, 224, 224]" \
    ${additional_options}
