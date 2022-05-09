#!/bin/bash


service orthanc start
jupyter notebook --port=8888 --no-browser --ip=0.0.0.0 --allow-root --NotebookApp.token='' --NotebookApp.disable_check_xsrf=True

