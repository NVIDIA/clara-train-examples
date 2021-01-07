#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

clear
echo running cmd $0 $1 $2 $3
CONFIG_FILE_NAME=config_train_Unet.json  # need to pass different names
GPU2USE=$1
#DATASET_JSON=$2

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"

# Data list containing all data
CONFIG_FILE=config/config_validation.json
ENVIRONMENT_FILE=config/environment.json

########################################### check on arguments
if [[ -z  $GPU2USE  ]] ;then
   GPU2USE=0,1,2,3
fi
export CUDA_VISIBLE_DEVICES=$GPU2USE
echo ------------------------------------
MMAR_CKPT=models/${CONFIG_FILE_NAME::-5}/model.pt #remove .json from file name

python -m torch.distributed.launch --nproc_per_node=2 --nnodes=1 --node_rank=0 \
    --master_addr="localhost" --master_port=1234 \
    -m medl.apps.evaluate \
    -m $MMAR_ROOT \
    -c $CONFIG_FILE \
    -e $ENVIRONMENT_FILE \
    --set \
    MMAR_CKPT=$MMAR_CKPT \
    print_conf=True \
    use_gpu=True \
    multi_gpu=True
