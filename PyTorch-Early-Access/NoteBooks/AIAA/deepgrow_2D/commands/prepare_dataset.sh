#!/usr/bin/env bash
set -f

my_dir="$(dirname "$0")"
. $my_dir/set_env.sh

tmpDataDir=$1
dataset_root=$2
dataset_json=$3
#additional_options="$*"
if [[ -z  $tmpDataDir ]]; then
    tmpDataDir="/claraDevDay/AIAA/tmp4Deepgrow_2DDataPrep/"
fi
if [[ -z  $dataset_root ]]; then
    dataset_root="/claraDevDay/Data/DecathlonDataset/Task09_Spleen/"
fi
if [[ -z  $dataset_json ]]; then
    #dataset_json="/claraDevDay/Data/DecathlonDataset/Task09_Spleen/dataset.json"
    dataset_json="/claraDevDay/AIAA/deepgrow_2D/config/dataset_5.json"
fi

rm -r $tmpDataDir

python3 -u -m deepgrow.prepare_dataset \
  --dataset_root $dataset_root \
  --dataset_json $dataset_json \
  --datalist_key "training" \
  --output $tmpDataDir \
  --dimensions 2 \
  --limit 0 \
  --split 0.9 \
  --relative_path \
  ${additional_options}

: '
# Few Other Examples:
./prepare_dataset.sh --help

./prepare_dataset.sh \
  --dataset_root "/workspace/data/MSD_Task09_Spleen" \
  --dataset_json "/workspace/data/MSD_Task09_Spleen/dataset.json" \
  --datalist_key "training" \
  --output "/workspace/data/deepgrow/2D/spleen_min" \
  --limit 1
'
