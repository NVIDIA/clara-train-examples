#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

chmod 664 nginx/config/.htpasswd
./stop.sh
sleep 2
echo -----------------------------
#docker-compose build --no-cache
#docker-compose -p aiaa-orthanc up --remove-orphans -d --build --no-cache
docker-compose -p aiaa-orthanc up --remove-orphans -d
sleep 5
docker logs claradevday-pt 2>&1 |grep token= | head -2
