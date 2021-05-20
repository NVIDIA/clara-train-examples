#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

clear
echo running cmd $0 $1 $2 $3
#CONFIG_FILE_NAME=$1
GPU2USE=$1

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"
additional_options="$*"

# Data list containing all data
CONFIG_FILE=config/config_train_Unet.json
ENVIRONMENT_FILE=config/environment.json

########################################### check on arguments
if [[ -z  $GPU2USE  ]] ;then
   GPU2USE=0,1
fi
export CUDA_VISIBLE_DEVICES=$GPU2USE
echo ------------------------------------

python -m torch.distributed.launch --nproc_per_node=2 \
    --nnodes=1 --node_rank=0 \
    --master_addr="localhost" --master_port=1234 \
    -m medl.apps.train \
    -m $MMAR_ROOT \
    -c $CONFIG_FILE \
    -e $ENVIRONMENT_FILE \
    --write_train_stats \
    --set \
    print_conf=True \
    multi_gpu=True \
    learning_rate=2e-4 \
    ${additional_options}
