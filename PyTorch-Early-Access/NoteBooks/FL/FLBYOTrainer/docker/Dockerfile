# SPDX-License-Identifier: Apache-2.0

FROM projectmonai/monai:latest

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y zip

#copy install nvflare whl to BYO trainer
RUN python3 -m pip install --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple nvflare==0.1.4

#overwrite the fed_server.template
COPY ./fed_server.template /opt/conda/lib/python3.8/site-packages/fl_startup/depot/

# For workshops copy content inside docker image
#COPY ./ /claraDevDay/

WORKDIR /claraDevDay/
EXPOSE 8888
CMD ["/usr/local/bin/jupyter", "lab", "/claraDevDay", "--ip", "0.0.0.0", "--port", "8888" ,"--allow-root","--no-browser"]
