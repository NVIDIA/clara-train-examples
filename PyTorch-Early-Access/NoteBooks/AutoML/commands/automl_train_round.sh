#!/usr/bin/env bash

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"
additional_options="$*"

# Data list containing all data
CONFIG_FILE=config/config_train.json
ENVIRONMENT_FILE=config/environment.json

echo ---------- removing uneeded Dir
rm -R ${MMAR_ROOT}/eval
echo -------------

python3 -u  -m medl.apps.train \
    -m $MMAR_ROOT \
    -c $CONFIG_FILE \
    -e $ENVIRONMENT_FILE \
    --write_train_stats \
    --set \
    print_conf=True \
    DATA_ROOT=$MMAR_ROOT/../../../../sampleData/ \
    DATASET_JSON=$MMAR_ROOT/../../../../sampleData/dataset_autoML8files.json \
    ${additional_options}
