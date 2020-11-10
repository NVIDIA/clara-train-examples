#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

cd ..
docker build . --rm -f Docker/Dockerfile -t claratrain_notebooks:3.1

