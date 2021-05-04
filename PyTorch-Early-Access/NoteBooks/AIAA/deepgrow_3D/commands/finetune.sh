#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

# NOTE:: `./finetune.sh multi_gpu=true` to run on multi-gpu

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"
additional_options="$*"

# Data list containing all data
CONFIG_FILE=config/config_train.json
ENVIRONMENT_FILE=config/environment.json

echo "CONFIG_FILE: ${CONFIG_FILE}"

python3 -u -m medl.apps.train \
  -m $MMAR_ROOT \
  -c $CONFIG_FILE \
  -e $ENVIRONMENT_FILE \
  --write_train_stats \
  --set \
  print_conf=True \
  epochs=200 \
  learning_rate=0.0001 \
  num_interval_per_valid=1 \
  use_gpu=True \
  multi_gpu=False \
  cudnn_benchmark=False \
  dont_load_ckpt_model=False \
  ${additional_options}
