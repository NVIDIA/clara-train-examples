#!/usr/bin/env bash

nvidia-smi
jupyter lab /claraDevDay --ip 0.0.0.0 --port 8890 --allow-root --no-browser
