#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

pip install jupyterlab-nvdashboard
jupyter labextension install jupyterlab-nvdashboard
echo ------jupyterlab intallation completed
nvidia-smi
echo ------------------

#jupyter lab /claraDevDay --ip 0.0.0.0 --port 8890 --allow-root --no-browser

jupyter lab /claraDevDay --ip 0.0.0.0 --allow-root --no-browser --config /claraDevDay/AIAA/OHIF/orthancKeycloak/config/jupyter_notebook_config.py
