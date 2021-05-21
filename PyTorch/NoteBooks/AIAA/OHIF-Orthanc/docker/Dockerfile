# SPDX-License-Identifier: Apache-2.0

# This dockerfile is used to publish the `ohif/viewer` image on dockerhub.
#
# It's a good example of how to build our static application and package it
# with a web server capable of hosting it as static content.
# SUMMARY
# --------------
# This dockerfile has two stages:
#
# 1. Building the React application for production
# 2. Setting up our Nginx (Alpine Linux) image w/ step one's output
#


# Stage 1: Build the application
FROM node:12.20.2-slim as builder

RUN mkdir /usr/src/app
WORKDIR /usr/src/app


# install git
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y git
#clone repo instead copy files below
#########################################
RUN git clone https://github.com/OHIF/Viewers.git .
COPY /src/Viewers/ .
##########################
#RUN git clone https://github.com/SachidanandAlle/Viewers.git .
#revert to commit in December to avoid OHIF master branch which introduced the annotartion viewing bug
#RUN git checkout 922561a5a477079f4fc9a9194ed93f27e22768c7 #did not work
#RUN git checkout efde6ed20ec495e5cb3f636aafc01e0c1a4e32df  #did not work either
#RUN git checkout 922561a5a477079f4fc9a9194ed93f27e22768c7 #no luck
#RUN git checkout 1248475776834f0626a21541b312e3ad1683c9e9  #first commint
#########################################

# Run the install before copying the rest of the files
RUN yarn config set workspaces-experimental true

RUN yarn install

ENV PATH /usr/src/app/node_modules/.bin:$PATH
ENV QUICK_BUILD true
# ENV GENERATE_SOURCEMAP=false
# ENV REACT_APP_CONFIG=config/default.js

RUN yarn run build

###########################################################################################
###########################################################################################
# Stage 2: Bundle the built application into a Docker container
# which runs Nginx using Alpine Linux
FROM nginx:1.15.5-alpine
RUN apk add --no-cache bash
RUN rm -rf /etc/nginx/conf.d
#COPY .docker/Viewer-v2.x /etc/nginx/conf.d
#COPY .docker/Viewer-v2.x/entrypoint.sh /usr/src/
COPY --from=builder /usr/src/app/.docker/Viewer-v2.x /etc/nginx/conf.d
COPY --from=builder /usr/src/app/.docker/Viewer-v2.x/entrypoint.sh /usr/src/
RUN chmod 777 /usr/src/entrypoint.sh
COPY --from=builder /usr/src/app/platform/viewer/dist /usr/share/nginx/html
EXPOSE 80
EXPOSE 443
ENTRYPOINT ["/usr/src/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
