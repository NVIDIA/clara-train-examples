#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

chmod 664 nginx/config/.htpasswd
./stop.sh
sleep 2
echo -----------------------------
#docker rmi aiaa-ohif:v4.0
#docker-compose build --no-cache
sleep 2
echo -----------------------------
docker-compose -p aiaa-orthanc up --remove-orphans -d


for i in {1..6}
do
   echo ---wait $i
   sleep 1
done
docker logs claradevday-pt 2>&1 |grep token= | head -2
