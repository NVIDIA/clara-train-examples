# SPDX-License-Identifier: Apache-2.0

FROM nvcr.io/nvidia/clara-train-sdk:v4.0

RUN apt-get update && apt-get upgrade -y
RUN pip install --upgrade pip
RUN apt update
RUN apt install -y build-essential

#### jupyterlab-nvdashboard dependences (nodesj and npm installation)
RUN curl -sL https://deb.nodesource.com/setup_12.x | bash -
RUN apt install -y nodejs
##RUN mv /usr/bin/python /usr/bin/python2 # dir doesn't exist !
RUN ln -s $(which python3) /usr/bin/python

####
#Prerequisites : JupyterLab 1.0 bokeh pynvml
RUN pip install pynvml
RUN pip install jupyter-server-proxy
####

### bokeh dependences
RUN pip install Jinja2 \
    && pip install numpy \
    && pip install packaging \
    && pip install pillow \
    && pip install python-dateutil \
    && pip install six  \
    && pip install tornado
RUN pip install bokeh
RUN pip install jupyterlab
RUN pip install jupyterlab-nvdashboard
RUN jupyter labextension install jupyterlab-nvdashboard

# For workshops copy content inside docker image
#COPY ./ /claraDevDay/

WORKDIR /claraDevDay/
EXPOSE 8888
CMD ["/usr/local/bin/jupyter", "lab", "/claraDevDay", "--ip", "0.0.0.0", "--port", "8888" ,"--allow-root","--no-browser"]
