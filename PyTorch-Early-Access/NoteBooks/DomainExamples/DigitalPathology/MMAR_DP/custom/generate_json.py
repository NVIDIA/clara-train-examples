import argparse
import json
import os
import random

TRAIN_NORMAL_FILE = "normal_train.txt"
TRAIN_TUMOR_FILE = "tumor_train.txt"
VALID_NORMAL_FILE = "normal_valid.txt"
VALID_TUMOR_FILE = "tumor_valid.txt"

WSI_IMAGE_FOLDER = "WSI/"

def read_file(file_path):
    coords = []
    infile = open(file_path)
    for i, line in enumerate(infile):
        info = line.strip('\n').split(',')
        coords.append(info)
    infile.close()
    return coords


def main():
    parser = argparse.ArgumentParser(description="prostate seg json generate")
    parser.add_argument("--json_temp",
                        action="store",
                        required=True,
                        help="full path of .json template file")
    parser.add_argument("--list_folder",
                        action="store",
                        help="path to list folder root")
    parser.add_argument("--json_out",
                        action="store",
                        required=True,
                        help="full path of .json output file")

    args = parser.parse_args()

    json_template = args.json_temp
    list_folder = args.list_folder
    json_out = args.json_out

    train_normal_path = list_folder + TRAIN_NORMAL_FILE
    train_tumor_path = list_folder + TRAIN_TUMOR_FILE
    valid_normal_path = list_folder + VALID_NORMAL_FILE
    valid_tumor_path = list_folder + VALID_TUMOR_FILE

    train_normal_label = read_file(train_normal_path)
    train_tumor_label = read_file(train_tumor_path)
    valid_normal_label = read_file(valid_normal_path)
    valid_tumor_label = read_file(valid_tumor_path)

    with open(json_template) as f:
        json_data = json.load(f)
        for i in range(len(train_normal_label)):
            info = train_normal_label[i]
            new_item = {}
            new_item["image"] = WSI_IMAGE_FOLDER + info[0] + ".tif"
            new_item["location"] = [int(info[2]), int(info[1])]
            new_item["label"] = [int(i) for i in info[3:]]
            to_append = "training"
            temp = json_data[to_append]
            temp.append(new_item)
        for i in range(len(train_tumor_label)):
            info = train_tumor_label[i]
            new_item = {}
            new_item["image"] = WSI_IMAGE_FOLDER + info[0] + ".tif"
            new_item["location"] = [int(info[2]), int(info[1])]
            new_item["label"] = [int(i) for i in info[3:]]
            to_append = "training"
            temp = json_data[to_append]
            temp.append(new_item)
        for i in range(len(valid_normal_label)):
            info = valid_normal_label[i]
            new_item = {}
            new_item["image"] = WSI_IMAGE_FOLDER + info[0] + ".tif"
            new_item["location"] = [int(info[2]), int(info[1])]
            new_item["label"] = [int(i) for i in info[3:]]
            to_append = "validation"
            temp = json_data[to_append]
            temp.append(new_item)
        for i in range(len(valid_tumor_label)):
            info = valid_tumor_label[i]
            new_item = {}
            new_item["image"] = WSI_IMAGE_FOLDER + info[0] + ".tif"
            new_item["location"] = [int(info[2]), int(info[1])]
            new_item["label"] = [int(i) for i in info[3:]]
            to_append = "validation"
            temp = json_data[to_append]
            temp.append(new_item)

        to_shuffle = "training"
        random.shuffle(json_data[to_shuffle])
        to_shuffle = "validation"
        random.shuffle(json_data[to_shuffle])

    with open(json_out, 'w') as f:
        json.dump(json_data, f, indent=4)

    return


if __name__ == "__main__":
    main()
