#!/usr/bin/env bash

my_dir="$(dirname "$(readlink -f "$0")")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"
GPU2USE=$1
additional_options="$*"

CONFIG_FILE=config/config_train.json
ENVIRONMENT_FILE=config/environment.json
if [[ -z  $GPU2USE  ]] ;then
   GPU2USE=0
fi
export CUDA_VISIBLE_DEVICES=$GPU2USE
echo using GPU $GPU2USE

INPUT_CKPT="${MMAR_ROOT}/models/model.pt"
OUTPUT_CKPT="${MMAR_ROOT}/models/model.ts"

python3 -u -m medl.apps.export \
    -m $MMAR_ROOT \
    -c $CONFIG_FILE \
    -e $ENVIRONMENT_FILE \
    --model_path "${INPUT_CKPT}" \
    --output_path "${OUTPUT_CKPT}" \
    --input_shape "[1, 3, 128, 128, 128]"

#    ${additional_options}
