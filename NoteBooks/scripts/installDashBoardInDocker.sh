#!/usr/bin/env bash

pip install jupyterlab-nvdashboard
jupyter labextension install jupyterlab-nvdashboard
echo ------------------
echo ------jupyterlab intallation completed
echo ------------------
#echo -- fix bokeh issue downgrad to 1.4.0
#pip uninstall -y bokeh
#pip install bokeh==1.4.0
#echo ------------------ bokeh installed
nvidia-smi
echo ------------------
useradd -m -u 1002 -s /bin/bash aharouni
#su aharouni

jupyter lab /claraDevDay --ip 0.0.0.0 --port 8890 --allow-root --no-browser
