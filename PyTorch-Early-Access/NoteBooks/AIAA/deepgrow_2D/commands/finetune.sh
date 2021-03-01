#!/usr/bin/env bash

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"
additional_options="$*"

# Data list containing all data
CONFIG_FILE=config/config_finetune.json
ENVIRONMENT_FILE=config/environment.json

multi_gpu=false
for option in $additional_options; do
  if [ "$option" = "multi_gpu=True" ]; then
    multi_gpu=true
  fi
done

if $multi_gpu; then
  GPU_COUNT=$(nvidia-smi -L | wc -l)
  python -m torch.distributed.launch --nproc_per_node=${GPU_COUNT} --nnodes=1 --node_rank=0 \
    --master_addr="localhost" --master_port=1234 \
    -m medl.apps.train \
    -m $MMAR_ROOT \
    -c $CONFIG_FILE \
    -e $ENVIRONMENT_FILE \
    --write_train_stats \
    --set \
    print_conf=True \
    epochs=100 \
    use_gpu=True \
    multi_gpu=True \
    ${additional_options}
else
  python3 -u -m medl.apps.train \
    -m $MMAR_ROOT \
    -c $CONFIG_FILE \
    -e $ENVIRONMENT_FILE \
    --write_train_stats \
    --set \
    print_conf=True \
    epochs=10 \
    use_gpu=True \
    multi_gpu=False \
    ${additional_options}
fi
