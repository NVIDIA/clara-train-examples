#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

./stopClaraTrainNoteBooks.sh

echo ------------------------------------------------
echo ------------------------------------------------
#docker-compose build --no-cache
docker-compose -p claratrain-triton up --remove-orphans -d

for i in {1..6}
do
   echo ---wait $i
   sleep 1
done
docker logs claradevday-pt 2>&1 |grep token= | tail -2
