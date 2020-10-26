#!/usr/bin/env bash

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

CONFIG_FILE_NAME=trn_base.json
TRTIS_INPUT_SHAPE="1 64 64 64"
MODEL_NAME=${CONFIG_FILE_NAME::-5}
echo "MMAR_ROOT set to $MMAR_ROOT"

# Data list containing all data

CKPT_DIR=$MMAR_ROOT/models/${CONFIG_FILE_NAME::-5}

python3 -u -m nvmidl.apps.export \
    --model_file_format CKPT \
    --model_file_path $CKPT_DIR \
    --model_name model \
    --input_node_names "NV_MODEL_INPUT" \
    --output_node_names NV_MODEL_OUTPUT \
    --trt_min_seg_size 50 \
  --trtis_export \
  --trtis_model_name ${CONFIG_FILE_NAME::-5} \
  --trtis_input_shape ${TRTIS_INPUT_SHAPE}

echo creating dir $CKPT_DIR/Triton/1
mkdir -p $CKPT_DIR/Triton/1
cp $CKPT_DIR/config.pbtxt $CKPT_DIR/Triton/config.pbtxt
mv $CKPT_DIR/config.pbtxt $CKPT_DIR/Triton/1/model.graphdef
