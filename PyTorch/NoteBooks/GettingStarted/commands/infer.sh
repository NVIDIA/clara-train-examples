#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

clear
echo running cmd $0 $1 $2 $3
CONFIG_FILE_NAME=config_train_Unet.json  # need to pass different names
GPU2USE=$1

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"

# Data list containing all data
CONFIG_FILE=config/config_inference.json
ENVIRONMENT_FILE=config/environment.json

########################################### check on arguments
if [[ -z  $GPU2USE  ]] ;then
   GPU2USE=0
fi
export CUDA_VISIBLE_DEVICES=$GPU2USE
echo ------------------------------------

#MMAR_CKPT=models/${CONFIG_FILE_NAME::-5}/model.pt #remove .json from file name
MMAR_TORCHSCRIPT=models/${CONFIG_FILE_NAME::-5}/model.ts #remove .json from file name

python3 -u  -m medl.apps.evaluate \
    -m $MMAR_ROOT \
    -c $CONFIG_FILE \
    -e $ENVIRONMENT_FILE \
    --set \
    MMAR_TORCHSCRIPT=$MMAR_TORCHSCRIPT \
    print_conf=True
