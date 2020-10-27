#!/usr/bin/env bash

cd ..
docker build . --rm -f Docker/Dockerfile -t claratrain_notebooks:3.1

