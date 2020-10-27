#!/usr/bin/env bash

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"
additional_options="$*"

# Data list containing all data
CONFIG_FILE=config/config_train.json
ENVIRONMENT_FILE=config/environment.json

echo ------------- AEH modification /gettingStarted/automl/a/W2_1_J2/commands/..
echo removing uneedded files
echo "MMAR_ROOT set to $MMAR_ROOT"
MMAR_ROOT=${MMAR_ROOT::-11}
echo "MMAR_ROOT set to $MMAR_ROOT"
rm ${MMAR_ROOT}/readMe.md
rm -R ${MMAR_ROOT}/eval
#rm -R ${MMAR_ROOT}/sampleData
#rm -R ${MMAR_ROOT}/scripts
rm -R ${MMAR_ROOT}/BYOC
rm -R ${MMAR_ROOT}/screenShots
shopt -s extglob
cd ${MMAR_ROOT}/config
rm !('environment.json'|'config_train.json')
rm -R ${MMAR_ROOT}/commands
rm ${MMAR_ROOT}/AutoML.ipynb
rm -R ${MMAR_ROOT}/.ipynb_checkpoints
rm -R ${MMAR_ROOT}/config/.ipynb_checkpoints
echo -------------

python3 -u  -m nvmidl.apps.train \
    -m $MMAR_ROOT \
    -c $CONFIG_FILE \
    -e $ENVIRONMENT_FILE \
    --write_train_stats \
    --set \
    DATA_ROOT=$MMAR_ROOT/../../../../../sampleData/ \
    DATASET_JSON=$MMAR_ROOT/../../../../../sampleData/dataset_autoML8files.json \
    ${additional_options}
