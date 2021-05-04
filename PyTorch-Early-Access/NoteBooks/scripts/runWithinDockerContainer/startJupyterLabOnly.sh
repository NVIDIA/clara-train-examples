#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

nvidia-smi
#jupyter lab /claraDevDay --ip 0.0.0.0 --port 8890 --allow-root --no-browser

jupyter lab /claraDevDay --ip 0.0.0.0 --port 8888 --allow-root --no-browser

#jupyter lab /claraDevDay --ip 0.0.0.0 --allow-root --no-browser --config /claraDevDay/AIAA/OHIF/orthancKeycloak/config/jupyter_notebook_config.py
