#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

FILEID="1jzeNU1EKnK81PyTsrx0ujfNl-t0Jo8uE"
FILNAME="Task09_Spleen.tar"
DEST_DIR=/claraDevDay/spleenData

mkdir -p $DEST_DIR
curl -c ./cookie -s -L "https://drive.google.com/uc?export=download&id=${FILEID}" > /dev/null
curl -Lb ./cookie "https://drive.google.com/uc?export=download&confirm=`awk '/download/ {print $NF}' ./cookie`&id=${FILEID}" -o $DEST_DIR/Task09_Spleen.tar

#unzip the tar
tar -C $DEST_DIR -xvf $DEST_DIR/Task09_Spleen.tar
