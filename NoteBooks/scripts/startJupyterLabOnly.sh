#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

nvidia-smi
useradd -m -u 1002 -s /bin/bash aharouni
jupyter lab /claraDevDay --ip 0.0.0.0 --port 8890 --allow-root --no-browser
