#!/usr/bin/env bash

pip install jupyterlab-nvdashboard
jupyter labextension install jupyterlab-nvdashboard
echo ------------------
echo ------jupyterlab intallation completed
nvidia-smi
echo ------------------

jupyter lab /claraDevDay --ip 0.0.0.0 --port 8890 --allow-root --no-browser
