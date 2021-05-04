#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

clear
echo running cmd $0 $1 $2 $3
CONFIG_FILE_NAME=$1
GPU2USE=$2

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh
echo "MMAR_ROOT set to $MMAR_ROOT"

CONFIG_FILE=config/$CONFIG_FILE_NAME
ENVIRONMENT_FILE=config/environment.json

########################################### check on arguments
if [[ -z  CONFIG_FILE_NAME  ]] ;then
   echo Need to pass in config.json
   exit
fi
if [[ -z  $GPU2USE  ]] ;then
   GPU2USE=0
fi
export CUDA_VISIBLE_DEVICES=$GPU2USE
echo ------------------------------------
MMAR_CKPT_DIR=models/${CONFIG_FILE_NAME::-5}_debug  #remove .json from file name
if [ -d "$MMAR_ROOT/$MMAR_CKPT_DIR" ]; then
    rm -r "$MMAR_ROOT/$MMAR_CKPT_DIR"
    sleep 2
fi
mkdir "$MMAR_ROOT/$MMAR_CKPT_DIR"
echo saving models to created dir "$MMAR_ROOT/$MMAR_CKPT_DIR"
cp ${MMAR_ROOT}/${CONFIG_FILE} ${MMAR_ROOT}/${MMAR_CKPT_DIR}/
echo ------------------------------------

#       --reports=summary,detail,iteration,kernel,tensor,node_op,group_node,expert_systems

dlprof \
       --reports=all \
       --formats=csv \
       --output_path=$MMAR_ROOT/$MMAR_CKPT_DIR \
       --key_node=global_step \
       --tb_dir=dlprof \
       --force=true \
  python3 -u  -m medl.apps.train \
    -m $MMAR_ROOT \
    -c $CONFIG_FILE \
    -e $ENVIRONMENT_FILE \
    --set \
    print_conf=True \
    disable_dlprof_debug=False \
    MMAR_CKPT_DIR=$MMAR_CKPT_DIR \
    epochs=1 \
    learning_rate=0.0001 \
    num_training_epoch_per_valid=20 \
    multi_gpu=false
