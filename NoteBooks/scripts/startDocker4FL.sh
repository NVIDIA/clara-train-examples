#!/bin/bash

# prune down copy of startDocker.sh
# Main difference is mapping network as --net=host

#DOCKER_IMAGE=nvcr.io/nvidia/clara-train-sdk:v3.0
DOCKER_IMAGE=nvcr.io/ea-nvidia-clara-train/clara-train-sdk:v3.1.03

DOCKER_Run_Name=claradevday

GPU_IDs=$1
#################################### check if parameters are empty
if [[ -z  $GPU_IDs ]]; then  #if no gpu is passed
    #GPU_IDs='0,1,2,3'
    # for all gpus use line below
    GPU_IDs=all
    # for 2 gpus use line below
    #GPU_IDs=2
    # for specific gpus as gpu#0 and gpu#2 use line below
    #GPU_IDs='"device=0,2"'
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

extraFlag=${extraFlag}" --net=host "

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
