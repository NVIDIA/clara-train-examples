#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

export PYTHONPATH="$PYTHONPATH:/opt/nvidia:"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export MMAR_ROOT=${DIR}/..
export PYTHONPATH="$PYTHONPATH:/opt/nvidia:$MMAR_ROOT/BYOC"
echo PYTHONPATH is $PYTHONPATH
