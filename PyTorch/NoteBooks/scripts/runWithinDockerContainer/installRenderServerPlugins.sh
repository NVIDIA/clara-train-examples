#!/bin/bash

# SPDX-License-Identifier: Apache-2.0

pip3 install --user /claraDevDay/Data/ClaraRender/src/ipyclararenderer-0.7.4a0-py2.py3-none-any.whl
#pip3 install --user /raid/users/aharouni/dockers/claraTrain/claraTrainExamples/PyTorch-Early-Access/NoteBooks/Data/ClaraRender/src/ipyclararenderer-0.7.4a0-py2.py3-none-any.whl

echo -----------step1 done
jupyter nbextension install --user --py --symlink ipyclararenderer
echo --------------------step2 done
jupyter nbextension enable --user --py ipyclararenderer
echo -----------------------------step3 done
jupyter labextension install --dev-build=False @jupyter-widgets/jupyterlab-manager
echo -------------------------------------step4 done
jupyter labextension install --dev-build=False js
echo --------------------all steps done
