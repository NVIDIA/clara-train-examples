#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

DOCKER_IMAGE=clara-train-wdocker:v4.0

DOCKER_Run_Name=claradevday-pt-wdocker

#################################### check if image exist, if not build it
docker images |grep ${DOCKER_IMAGE%:*} # remove the :0.1
dockerNameExist=$?
if ((${dockerNameExist}==0)) ;then
  echo --- docker image ${DOCKER_Run_Name} exist
else
  echo --- docker image ${DOCKER_Run_Name} doesnot exist, building it
  docker build -f Dockerfile --tag ${DOCKER_IMAGE} .
  echo ----------- docker image ${DOCKER_Run_Name} built
fi

jnotebookPort=$1
GPU_IDs=$2
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
echo -----------------------------------
echo starting docker for ${DOCKER_IMAGE} using GPUS ${GPU_IDs} jnotebookPort ${jnotebookPort}
echo -----------------------------------

extraFlag="-it "
#cmd2run="/bin/bash"
cmd2run="jupyter lab /claraDevDay --ip 0.0.0.0 --port 8888 --allow-root --no-browser"

#extraFlag=${extraFlag}" -p "${jnotebookPort}":8888"
extraFlag=${extraFlag}" --net=host "
#extraFlag=${extraFlag}" -u $(id -u):$(id -g) -v /etc/passwd:/etc/passwd -v /etc/group:/etc/group "

#--shm-size=1g --ulimit memlock=-1 --ulimit stack=67108864 \
docker run --rm ${extraFlag} \
  --name=${DOCKER_Run_Name} \
  --gpus ${GPU_IDs} \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ${PWD}/../../:/claraDevDay/ \
  -e HOST_CLARA_DEVDAY=${PWD}/../../ \
  -w /claraDevDay/scripts \
  --runtime=nvidia \
  --ipc=host \
  ${DOCKER_IMAGE} \
  ${cmd2run}

echo ------------------ exited from docker image
