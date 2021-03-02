import os
import sys

from argparse import ArgumentParser
import logging
import json
import time
import numpy as np

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from annotation import Annotation

ROOT_DATA_PATH="/claraDevDay/Data/DP_CAMELYON16/"

TRAIN_ANO_PATH = ROOT_DATA_PATH+"/jsons/train"
VALID_ANO_PATH = ROOT_DATA_PATH+"/jsons/valid"

TRAIN_NORMAL_LOC_PATH = ROOT_DATA_PATH+"/coords/normal_train.txt"
TRAIN_TUMOR_LOC_PATH = ROOT_DATA_PATH+"/coords/tumor_train.txt"
VALID_NORMAL_LOC_PATH = ROOT_DATA_PATH+"/coords/normal_valid.txt"
VALID_TUMOR_LOC_PATH = ROOT_DATA_PATH+"/coords/tumor_valid.txt"

TRAIN_NORMAL_OUT_PATH = ROOT_DATA_PATH+"/LocLabel/normal_train.txt"
TRAIN_TUMOR_OUT_PATH = ROOT_DATA_PATH+"/LocLabel/tumor_train.txt"
VALID_NORMAL_OUT_PATH = ROOT_DATA_PATH+"/LocLabel/normal_valid.txt"
VALID_TUMOR_OUT_PATH = ROOT_DATA_PATH+"/LocLabel/tumor_valid.txt"

IMG_SIZE = 768
SUB_SIZE = 256

def loclabel_gen(ano_path, loc_path, out_path):
    pids = list(map(lambda x: x.strip('.json'), os.listdir(ano_path)))

    annotations = {}
    for pid in pids:
        pid_json_path = os.path.join(ano_path, pid + '.json')
        anno = Annotation()
        anno.from_json(pid_json_path)
        annotations[pid] = anno

    coords = []
    infile = open(loc_path)
    for i, line in enumerate(infile):
        pid, x_center, y_center = line.strip('\n').split(',')
        coords.append((pid, x_center, y_center))
    infile.close()

    num_sample = len(coords)
    print(f"Total sample: {num_sample}")

    outfile = open(out_path,'w')
    for index in range(num_sample):
        pid, x_center, y_center = coords[index]
        x_center = int(x_center)
        y_center = int(y_center)

        x_top_left = int(x_center - IMG_SIZE / 2)
        y_top_left = int(y_center - IMG_SIZE / 2)

        label=[]
        for x_idx in range(3):
            for y_idx in range(3):
                # (x, y) is the center of each patch
                x = x_top_left + int((x_idx + 0.5) * SUB_SIZE)
                y = y_top_left + int((y_idx + 0.5) * SUB_SIZE)
                # get label information according to annotation
                if annotations[pid].inside_polygons((x, y), True):
                    label.append(1)
                else:
                    label.append(0)
                # write output
        outfile.write(f"{pid.lower()}, {x_center}, {y_center}, {str(label)[1:-1]}\n")

        if index % 100 == 0:
            print(index)

    outfile.close()

def main():
    loclabel_gen(TRAIN_ANO_PATH, TRAIN_TUMOR_LOC_PATH, TRAIN_TUMOR_OUT_PATH)
    return
    loclabel_gen(TRAIN_ANO_PATH, TRAIN_NORMAL_LOC_PATH, TRAIN_NORMAL_OUT_PATH)
    loclabel_gen(VALID_ANO_PATH, VALID_TUMOR_LOC_PATH, VALID_TUMOR_OUT_PATH)
    loclabel_gen(VALID_ANO_PATH, VALID_NORMAL_LOC_PATH, VALID_NORMAL_OUT_PATH)

if __name__ == "__main__":
    main()
