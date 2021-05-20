#!/usr/bin/env bash

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"
additional_options="$*"

# Data list containing all data
CONFIG_FILE=config/config_train_smartcache.json
ENVIRONMENT_FILE=config/environment.json

python3 -u -m medl.apps.train \
    -m $MMAR_ROOT \
    -c $CONFIG_FILE \
    -e $ENVIRONMENT_FILE \
    --write_train_stats \
    --set \
    print_conf=True \
    MMAR_CKPT_DIR="models_sc/"
    ${additional_options}
