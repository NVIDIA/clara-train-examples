#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

# NOTE:: `./train.sh multi_gpu=true` to run on multi-gpu

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"
GPU2USE=$1
additional_options="$*"
echo $additional_options
# Data list containing all data
CONFIG_FILE=config/config_train.json
ENVIRONMENT_FILE=config/environment.json
if [[ -z  $GPU2USE  ]] ;then
   GPU2USE=0
fi
export CUDA_VISIBLE_DEVICES=$GPU2USE

echo "CONFIG_FILE: ${CONFIG_FILE}"

python3 -u -m medl.apps.train \
  -m $MMAR_ROOT \
  -c $CONFIG_FILE \
  -e $ENVIRONMENT_FILE \
  --write_train_stats \
  --set \
  print_conf=True \
  epochs=5 \
  learning_rate=0.0001 \
  num_interval_per_valid=1 \
  use_gpu=True \
  multi_gpu=False \
  cudnn_benchmark=False \
  dont_load_ckpt_model=True \
  ${additional_options}

: '
# Few Examples:
./train.sh \
  epochs=5 \
  DATA_ROOT=/workspace/data/deepgrow/3D/spleen_min \
  DATASET_JSON=/workspace/data/deepgrow/3D/spleen_min/dataset_0.json

./train.sh \
  epochs=5 \
  amp=True \
  DATA_ROOT=/workspace/data/deepgrow/3D/spleen_min \
  DATASET_JSON=/workspace/data/deepgrow/3D/spleen_min/dataset_0.json
'
