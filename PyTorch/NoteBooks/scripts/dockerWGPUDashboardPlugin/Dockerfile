# SPDX-License-Identifier: Apache-2.0

FROM nvcr.io/nvidia/clara-train-sdk:v4.1

# Fix for clara vis / monai label/ Down side tensorboard is gone by this update!
RUN pip3 install --upgrade jupyterlab
RUN pip3 install --force-reinstall itk

#install gpu dash board
RUN pip install jupyterlab jupyterlab-nvdashboard jupyterlab_execute_time

# install clara visualizeation
RUN pip install clara-viz clara-viz-core clara-viz-widgets

# install / upgrad dlprof
#RUN pip install nvidia-pyindex
#RUN pip install nvidia-dlprof
#RUN pip install nvidia-dlprofviewer==1.8

# install nvtop
# breaks driver in the docker error: Failed to initialize NVML: Driver/library version mismatch
#RUN apt install -y nvtop

WORKDIR /claraDevDay/
EXPOSE 8888
CMD ["/usr/local/bin/jupyter", "lab", "/claraDevDay", "--ip", "0.0.0.0", "--port", "8888" ,"--allow-root","--no-browser"]
