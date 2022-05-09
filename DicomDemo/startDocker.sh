#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

DOCKER_Run_Name=dicom-demo

jnotebookPort=8888
orthanc_webPort=8042
orthanc_dicomPort=4242
docker run --rm \
    --name=${DOCKER_Run_Name} \
    -p $jnotebookPort:8888 \
    -p $orthanc_webPort:8042 \
    -p $orthanc_dicomPort:4242 \
    -v ${PWD}/content/:/workshop/content \
    dicomdemo

for i in {1..4}
do
   echo ---wait $i
   sleep 1
done

docker logs ${DOCKER_Run_Name} 2>&1 |grep token= | tail -2
