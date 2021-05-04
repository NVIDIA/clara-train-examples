#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

clear
my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"

additional_options="$*"
AUTOML_DIR_NAME=$1
########################################### check on arguments
if [[ -z  $AUTOML_DIR_NAME  ]] ;then
   AUTOML_DIR_NAME=trn_autoML
fi
########################################### check on arguments
TRAIN_CONFIG=${AUTOML_DIR_NAME}.json

echo removing dir ${AUTOML_DIR_NAME}
rm -R $MMAR_ROOT/automl/${AUTOML_DIR_NAME}

#WORKERS="0:0:1:1"  # for 4 workers and 2 gpus (wroker 0, 1 share gpu0 while worker 2,3 share gpu 1)
WORKERS="0:1:2:3" # for 4 workers and 4 gpus
#WORKERS="0:0:0:0:0:0:0:0"  # for 8 workers sharing 1 gpu

python -u -m medl.apps.automl.train \
    -m $MMAR_ROOT \
    --set \
    run_id=${AUTOML_DIR_NAME} \
    trainconf=${TRAIN_CONFIG} \
    workers=${WORKERS} \
    traceout=console \
    ${additional_options}
