#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export MMAR_ROOT=${DIR}/..
export PYTHONPATH="$PYTHONPATH:/opt/nvidia:$MMAR_ROOT/custom"
