#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

# This script will:
# 1 take an input = group number
# 2 make a copy clara folder as claraDevDay_$GROUP_NO
# 3 launch the docker so you can have multiple users on the same machine
# user can open the jupyter lab at port 8890 + GROUP_NO
# so group 3 will use dir  claraDevDay_3 on port 8893

DOCKER_IMAGE=nvcr.io/nvidia/clara-train-sdk:v3.1

GROUP_NO=$1
if [[ -z  $GROUP_NO ]]; then
    echo error missing arg group number
    exit
fi
jnotebookPort=$(( 8890 + $GROUP_NO ))
GPU_IDs=$2

DOCKER_Run_Name=claradevday_$GROUP_NO
#################################### Make a Copy of clara notebook folder for each group
HOST_CLARA_ROOT=${PWD}/../../claraDevDay_$GROUP_NO
#cp -r ${PWD}/../ $HOST_CLARA_ROOT
echo ---------------
echo copied claraDevDay to $HOST_CLARA_ROOT
echo ---------------
#################################### check if parameters are empty
if [[ -z  $jnotebookPort ]]; then
    jnotebookPort=8890
fi
if [[ -z  $GPU_IDs ]]; then  #if no gpu is passed
    # for all gpus use line below
    GPU_IDs=all
    # for 2 gpus use line below
    #GPU_IDs=2
    # for specific gpus as gpu#0 and gpu#2 use line below
#    GPU_IDs='"device=1,2,3"'
fi
#################################### check if name is used then exit
docker ps -a|grep ${DOCKER_Run_Name}
dockerNameExist=$?
if ((${dockerNameExist}==0)) ;then
  echo --- dockerName ${DOCKER_Run_Name} already exist
  echo ----------- attaching into the docker
  docker exec -it ${DOCKER_Run_Name} /bin/bash
  exit
fi

echo -----------------------------------
echo starting docker for ${DOCKER_IMAGE} using GPUS ${GPU_IDs}
echo -----------------------------------

extraFlag="-it "
cmd2run="/bin/bash"
#cmd2run="jupyter lab /claraDevDay --ip 0.0.0.0 --port 8890 --allow-root --no-browser"

extraFlag=${extraFlag}" -p "${jnotebookPort}":8890 "

echo open web browser with token given yourip:${jnotebookPort} to access it

docker run --rm ${extraFlag} \
  --name=${DOCKER_Run_Name} \
  --gpus ${GPU_IDs} \
  -v $HOST_CLARA_ROOT:/claraDevDay/ \
  -w /claraDevDay/scripts \
  --runtime=nvidia \
  --shm-size=1g --ulimit memlock=-1 --ulimit stack=67108864 \
  ${DOCKER_IMAGE} \
  ${cmd2run}
