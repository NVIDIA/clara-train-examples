#!/usr/bin/env bash

clear
my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"

additional_options="$*"
AUTOML_DIR_NAME=$1
HANDLER_JSON=$2
########################################### check on arguments
if [[ -z  $AUTOML_DIR_NAME  ]] ;then
   AUTOML_DIR_NAME=trn_autoML_Enum
fi
if [[ -z  $HANDLER_JSON  ]] ;then
   HANDLER_JSON=config_automl_BYO_handler.json
fi
########################################### check on arguments
TRAIN_CONFIG=${AUTOML_DIR_NAME}.json

echo removing dir ${AUTOML_DIR_NAME}
rm -R $MMAR_ROOT/models/${AUTOML_DIR_NAME}

python -u -m nvmidl.apps.automl.train \
    -m $MMAR_ROOT \
    --automlconf ${HANDLER_JSON} \
    --set \
    run_id=${AUTOML_DIR_NAME} \
    trainconf=${TRAIN_CONFIG} \
    workers=0:0:0:0:0:0:0:0 \
    traceout=both \
    ${additional_options}


#    workers=0:1:2:3 \
#    workers=0:0:0:0:0:0:0:0 \
#    engTrace='hello.log' \
