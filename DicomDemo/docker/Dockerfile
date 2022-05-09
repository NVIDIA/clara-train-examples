# SPDX-License-Identifier: Apache-2.0

#FROM ubuntu:latest
FROM ubuntu:20.04
#RUN apt-get update && apt-get -y update
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -y update
RUN apt-get install -y build-essential python3.6 python3-pip python3-dev

RUN apt-get install -y orthanc
RUN apt-get install -y orthanc-dicomweb
RUN apt-get install -y dicom3tools

RUN pip3 install jupyter

RUN pip3 install pydicom 
RUN pip3 install pynetdicom
RUN pip3 install pillow
RUN pip3 install numpy
RUN pip3 install requests

# Configuring access to Jupyter
RUN mkdir /workshop
RUN jupyter notebook --generate-config --allow-root

# Configure Orthanc
#RUN mkdir /etc/orthanc
WORKDIR /etc/orthanc
COPY orthanc.json .
COPY dicomweb.json .

# Create working directory to add repo.
WORKDIR /workshop

# Load contents into student working directory.
#ADD . .

# Create working directory for students.
#WORKDIR /workshop/content

# Jupyter listens on 8888.
EXPOSE 8888
EXPOSE 8042

# Please see `entrypoint.sh` for details on how this content
# is launched.
ADD entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

