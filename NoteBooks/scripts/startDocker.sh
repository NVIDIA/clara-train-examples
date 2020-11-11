#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

#DOCKER_IMAGE=nvcr.io/nvidia/clara-train-sdk:v3.0
DOCKER_IMAGE=nvcr.io/nvidia/clara-train-sdk:v3.1

DOCKER_Run_Name=claradevday

jnotebookPort=$1
GPU_IDs=$2
AIAA_PORT=$3
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
if [[ -z  $AIAA_PORT ]]; then
    AIAA_PORT=5000
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
echo starting docker for ${DOCKER_IMAGE} using GPUS ${GPU_IDs} jnotebookPort ${jnotebookPort} and AIAA port ${AIAA_PORT}
echo -----------------------------------

extraFlag="-it "
cmd2run="/bin/bash"

extraFlag=${extraFlag}" -p "${jnotebookPort}":8890 -p "${AIAA_PORT}":80"
#extraFlag=${extraFlag}" --net=host "
#extraFlag=${extraFlag}" -u $(id -u):$(id -g) -v /etc/passwd:/etc/passwd -v /etc/group:/etc/group "

echo starting please run "./installDashBoardInDocker.sh" to install the lab extensions then start the jupeter lab
echo once completed use web browser with token given yourip:${jnotebookPort} to access it

docker run --rm ${extraFlag} \
  --name=${DOCKER_Run_Name} \
  --gpus ${GPU_IDs} \
  -v ${PWD}/../:/claraDevDay/ \
  -w /claraDevDay/scripts \
  --runtime=nvidia \
  --shm-size=1g --ulimit memlock=-1 --ulimit stack=67108864 \
  ${DOCKER_IMAGE} \
  ${cmd2run}

echo -- exited from docker image
