#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"
additional_options="$*"

# Data list containing all data
CONFIG_FILE=config/config_train.json
ENVIRONMENT_FILE=config/environment.json

echo "CONFIG_FILE: ${CONFIG_FILE}"

GPU_COUNT=2 #$(nvidia-smi -L | wc -l)
python -m torch.distributed.launch --nproc_per_node=${GPU_COUNT} --nnodes=1 --node_rank=0 \
  --master_addr="localhost" --master_port=1234 \
  -m medl.apps.train \
  -m $MMAR_ROOT \
  -c $CONFIG_FILE \
  -e $ENVIRONMENT_FILE \
  --write_train_stats \
  --set \
  print_conf=True \
  epochs=100 \
  learning_rate=0.0001 \
  num_interval_per_valid=1 \
  use_gpu=True \
  multi_gpu=True \
  cudnn_benchmark=False \
  dont_load_ckpt_model=False \
  ${additional_options}
