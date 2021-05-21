#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

#DOCKER_IMAGE=clara-train-nvdashboard:v4.0
DOCKER_IMAGE=nvcr.io/nvidia/clara-train-sdk:v4.0

DOCKER_Run_Name=claradevday-pt

jnotebookPort=$1
GPU_IDs=$2
AIAA_PORT=$3
#################################### check if parameters are empty
if [[ -z  $jnotebookPort ]]; then
    jnotebookPort=3030
fi
if [[ -z  $GPU_IDs ]]; then  #if no gpu is passed
    # for all gpus use line below
    GPU_IDs=all
    # for 2 gpus use line below
    #GPU_IDs=2
    # for specific gpus as gpu#0 and gpu#2 use line below
#    GPU_IDs='"device=1,2,3"'
fi
#################################### check if name is used then attache to it
docker ps -a|grep ${DOCKER_Run_Name}
dockerNameExist=$?
if ((${dockerNameExist}==0)) ;then
  echo --- dockerName ${DOCKER_Run_Name} already exist
  echo ----------- attaching into the docker
  docker exec -it ${DOCKER_Run_Name} /bin/bash
  exit
fi

echo -----------------------------------
echo starting docker for ${DOCKER_IMAGE} using GPUS ${GPU_IDs} jnotebookPort ${jnotebookPort}
echo -----------------------------------

if true; then # immediately start Jupyter
  extraFlag="-d "
  cmd2run="jupyter lab /claraDevDay --ip 0.0.0.0 --port 8888 --allow-root --no-browser"
else # run interactively
  extraFlag="-it "
  cmd2run="/bin/bash"
fi

extraFlag=${extraFlag}" -p "${jnotebookPort}":8888 -p "3031":5000"
#extraFlag=${extraFlag}" --net=host "
#extraFlag=${extraFlag}" -u $(id -u):$(id -g) -v /etc/passwd:/etc/passwd -v /etc/group:/etc/group "

  #--shm-size=1g --ulimit memlock=-1 --ulimit stack=67108864 \
docker run --rm ${extraFlag} \
  --name=${DOCKER_Run_Name} \
  --gpus ${GPU_IDs} \
  -v ${PWD}/../:/claraDevDay/ \
  -v /raid/users/aharouni/data:/data \
  -w /claraDevDay/scripts \
  --runtime=nvidia \
  --ipc=host \
  ${DOCKER_IMAGE} \
  ${cmd2run}

for i in {1..6}
do
   echo ---wait $i
   sleep 1
done
docker logs claradevday-pt 2>&1 |grep token= | head -2

#echo ------------------ exited from docker image
