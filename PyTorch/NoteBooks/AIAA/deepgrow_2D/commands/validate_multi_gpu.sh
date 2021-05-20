#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

# NOTE:: `./validate.sh multi_gpu=true` to run on multi-gpu
# NOTE:: `./validate.sh ckpt=true` to run on validation using checkpoint

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"
additional_options="$*"

# Data list containing all data
CONFIG_FILE=config/config_validation.json
ENVIRONMENT_FILE=config/environment.json

echo "CONFIG_FILE: ${CONFIG_FILE}"

GPU_COUNT=2 #$(nvidia-smi -L | wc -l)
python -m torch.distributed.launch --nproc_per_node=${GPU_COUNT} --nnodes=1 --node_rank=0 \
  --master_addr="localhost" --master_port=1234 \
  -m medl.apps.evaluate \
  -m $MMAR_ROOT \
  -c $CONFIG_FILE \
  -e $ENVIRONMENT_FILE \
  --set \
  print_conf=True \
  use_gpu=True \
  multi_gpu=True \
  dont_load_ts_model=False \
  dont_load_ckpt_model=True \
  ${additional_options}
