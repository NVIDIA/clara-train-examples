#!/usr/bin/env bash

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

echo "MMAR_ROOT set to $MMAR_ROOT"

GROUND_TRUTH_DIR=/workspace/data/medical/pathology/ground_truths
echo "Ground truth directory: ${GROUND_TRUTH_DIR}"

DATASET_JSON=${MMAR_ROOT}/config/dataset.json
echo "Path to dataset.json: ${DATASET_JSON}"

EVAL_DIR=${MMAR_ROOT}/eval
echo "Evaluation output directory: ${EVAL_DIR}"

python3 ${MMAR_ROOT}/custom/lesion_froc.py \
    -d ${DATASET_JSON} \
    -e ${EVAL_DIR} \
    -g ${GROUND_TRUTH_DIR}
