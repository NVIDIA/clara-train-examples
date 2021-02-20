#!/bin/bash

stop.sh
sleep 2
echo -----------------------------_
#docker-compose -p aiaa-orthanc up --remove-orphans -d --build
docker-compose -p aiaa-orthanc up --remove-orphans -d
sleep 5
docker logs claradevday-pt 2>&1 |grep token=
