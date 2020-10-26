#!/usr/bin/env bash

nvidia-smi
useradd -m -u 1002 -s /bin/bash aharouni
jupyter lab /claraDevDay --ip 0.0.0.0 --port 8890 --allow-root --no-browser
