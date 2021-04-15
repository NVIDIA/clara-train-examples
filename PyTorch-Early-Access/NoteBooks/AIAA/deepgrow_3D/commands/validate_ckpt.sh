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

python3 -u -m medl.apps.evaluate \
  -m $MMAR_ROOT \
  -c $CONFIG_FILE \
  -e $ENVIRONMENT_FILE \
  --set \
  print_conf=True \
  use_gpu=True \
  multi_gpu=False \
  dont_load_ts_model=True \
  dont_load_ckpt_model=False \
  ${additional_options}
