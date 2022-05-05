#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

# Stop container if started with StartDocker.sh
echo Stopping claradevday-pt
docker stop claradevday-pt

echo Stopping docker compose
docker-compose -p claratrain-triton down --remove-orphans

