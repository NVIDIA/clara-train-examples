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

#clone OHIF repo then copy AIAA files below into it
#########################################
RUN git clone https://github.com/OHIF/Viewers.git .
# fix to to Commits on May 17, 2021
RUN git checkout f0d13a7acd9e594bbeb153f227a906dffd708bff
#copy AIAA plugin
COPY /src/Viewers/ .
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
