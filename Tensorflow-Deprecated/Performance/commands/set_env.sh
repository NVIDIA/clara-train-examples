#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

export PYTHONPATH="$(pwd)/../BYOC:$PYTHONPATH:/opt/nvidia"
echo PYTHONPATH is $PYTHONPATH
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export MMAR_ROOT=${DIR}/..
