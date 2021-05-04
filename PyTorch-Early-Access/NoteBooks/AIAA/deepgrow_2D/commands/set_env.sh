#!/usr/bin/env bash

# SPDX-License-Identifier: Apache-2.0

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
export MMAR_ROOT=$(readlink -f "${DIR}"/..)
export PYTHONPATH="$PYTHONPATH:/opt/nvidia:$MMAR_ROOT/custom"
