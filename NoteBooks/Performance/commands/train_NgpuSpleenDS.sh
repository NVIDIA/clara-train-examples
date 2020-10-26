#!/usr/bin/env bash

clear
my_dir="$(dirname "$0")"
. $my_dir/set_env.sh
echo "MMAR_ROOT set to $MMAR_ROOT"

#CONFIG_FILE_NAME=trn_novograd_amp_4gpu.json
CONFIG_FILE_NAME=$1
CONFIG_FILE=config/$CONFIG_FILE_NAME
ENVIRONMENT_FILE=config/environment.json
NGPU=4
#CONFIG_FILE_NAME=${CONFIG_FILE_NAME::-5}}_${NGPU}gpu.json

########################################### check on arguments
if [[ -z  $CONFIG_FILE_NAME  ]] ;then
    echo error need a CONFIG_FILE_NAME to be passed in, exiting
    exit
fi
echo ------------------------------------
MMAR_CKPT_DIR=models/${CONFIG_FILE_NAME::-5} #remove .json from file name
if [ -d "$MMAR_ROOT/$MMAR_CKPT_DIR" ]; then
    rm -r "$MMAR_ROOT/$MMAR_CKPT_DIR"
    sleep 2
    echo deleted dir "$MMAR_ROOT/$MMAR_CKPT_DIR"
fi
echo ------------------------------------
mkdir "$MMAR_ROOT/$MMAR_CKPT_DIR"
ls -la "$MMAR_ROOT/$MMAR_CKPT_DIR"
echo saving models to created dir "$MMAR_ROOT/$MMAR_CKPT_DIR"
cp ${MMAR_ROOT}/${CONFIG_FILE} ${MMAR_ROOT}/${MMAR_CKPT_DIR}/
echo ------------------------------------

(time \
mpirun -np ${NGPU} -H localhost:${NGPU} -bind-to none -map-by slot \
    -x NCCL_DEBUG=INFO -x LD_LIBRARY_PATH -x PATH -mca pml ob1 -mca btl ^openib --allow-run-as-root \
    python3 -u  -m nvmidl.apps.train \
    -m $MMAR_ROOT \
    -c $CONFIG_FILE \
    -e $ENVIRONMENT_FILE \
    --set \
    DATA_ROOT=/workspace/data/Task09_Spleen \
    DATASET_JSON=$MMAR_ROOT/config/dataset_original.json \
    multi_gpu=true \
    MMAR_CKPT_DIR=$MMAR_CKPT_DIR) | tee $MMAR_ROOT/$MMAR_CKPT_DIR/$CONFIG_FILE_NAME.log

#    learning_rate=0.001 \
#    epochs=800 \
#    num_training_epoch_per_valid=5 \
