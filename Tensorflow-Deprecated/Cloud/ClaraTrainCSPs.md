<!--- SPDX-License-Identifier: Apache-2.0 -->

# Clara Train - Getting started with a Cloud Service Provider

Researchers who do not have access to a local GPU workstation or server can easily get started with the Clara Train SDK using a GPU-enabled instance from a Cloud Service Provider (CSP).  The following services have been validated; other CSPs may be used with similar configurations:



*   Amazon Web Services (AWS)
*   Google Cloud Platform Services (GCP)
*   Microsoft Azure Cloud Services (Azure)


## Recommended system and instance configuration



*   Hardware:
    *   GPU: V100 16GB or 32GB
    *   ~8 vCPU w/ AVX
    *   64GB memory
    *   100GB storage
    *   AWS [p3.2xlarge](https://aws.amazon.com/ec2/instance-types/p3/)
    *   GCP [n1-standard-16](https://cloud.google.com/compute/docs/machine-types#n1_machine_types) + [nvidia-tesla-v100](https://cloud.google.com/compute/docs/gpus)
    *   Azure [Standard\_NC6s\_v3](https://docs.microsoft.com/en-us/azure/virtual-machines/ncv3-series) 
*   OS and software stack:
    *   Ubuntu LTS or similar, Docker, nvidia-container-runtime
    *   AWS: [Deep Learning Base AMI (Ubuntu 18.04)](https://aws.amazon.com/marketplace/pp/B07Y3VDBNS)
    *   GCP: [NVIDIA GPU-Optimized Image for Deep Learning, ML & HPC](https://console.cloud.google.com/marketplace/details/nvidia-ngc-public/nvidia_gpu_cloud_image?pli=1)
    *   Azure: [NVIDIA GPU-Optimized Image for AI & HPC](https://azuremarketplace.microsoft.com/en-us/marketplace/apps/nvidia.ngc_azure_17_11?tab=Overview) 
*   Network and security
    *   Ports
        *   SSH - 22
        *   JupyterLab - 8888 or 8890 as in the following examples
        *   AIAA - 5000
        *   HTTP/HTTPS
    *   SSH authentication via shared key identity


## CSP-specific Configuration


### AWS

An overview of NGC on AWS can be found in the NGC Docs at [https://docs.nvidia.com/ngc/ngc-deploy-public-cloud/ngc-aws/index.html](https://docs.nvidia.com/ngc/ngc-deploy-public-cloud/ngc-aws/index.html).


### GCP

An overview of NGC on GCP can be found in the NGC Docs at [https://docs.nvidia.com/ngc/ngc-deploy-public-cloud/ngc-gcp/index.html](https://docs.nvidia.com/ngc/ngc-deploy-public-cloud/ngc-gcp/index.html).

To use an external SSH client, enable [OS Login](https://cloud.google.com/compute/docs/instances/managing-instance-access#enable_oslogin) by editing the VM instance configuration to add



*   the `enable-oslogin, TRUE` metadata key, value pair
*   your public SSH key
    *   It may be necessary to use the web-based SSH console to manually add your public key in `~/.ssh/authorized_keys`
    *   When the ssh key is added manually, you will also have to enable sudo access using `visudo` and adding:
`<username>	ALL=(ALL) NOPASSWD:ALL`

To open the ports necessary for Clara Train AIAA and JupyterLab, create a [VPC Firewall rule](https://cloud.google.com/vpc/docs/firewalls?hl=en_US) allowing access on ports 5000 and 8890.  This can be done in two steps:



*   edit the VM instance details to add a network label
*   under network interfaces click to view details, then use VPC Network > Firewall to create a firewall rule for ports 5000 and 8890 targeting the network label added above

**NOTE**:  GCP Ubuntu instances set a default umask of 0077, which can cause issues for users mounting directories in the Clara Train docker container.  This can be changed by setting


```
umask 0002
```


To make this persistent, add `umask 0002` to your user `~/.bashrc` configuration.  If there are existing files with restrictive permissions, you may need to run

chmod -R a+rX ~/*

If there are files with root ownership, e.g., from running other containers, you may need sudo in the above chmod command.

The GCP GPU-optimized image does not register the nvidia-container-runtime in `/etc/docker/daemon.json`.  While this isn’t strictly necessary for Docker versions >=19.03, it can cause errors in scripts that explicitly specify the runtime using `docker run --runtime=nvidia`.  To work around this, register the runtime in `/etc/docker/daemon.json` with:


```
    sudo tee /etc/docker/daemon.json <<EOF
    {
        "runtimes": {
            "nvidia": {
                "path": "/usr/bin/nvidia-container-runtime",
                "runtimeArgs": []
            }
        }
    }
    EOF
    sudo pkill -SIGHUP dockerd
```


Some examples in the Clara Train Getting Started notebooks require docker-compose.  This can be installed following the directions here: [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/)


### Azure

An overview of NGC on Azure can be found in the NGC Docs at [https://docs.nvidia.com/ngc/ngc-deploy-public-cloud/ngc-azure/index.html](https://docs.nvidia.com/ngc/ngc-deploy-public-cloud/ngc-azure/index.html).

**NOTE**:  Azure Ubuntu instances set a default umask of 0077, which can cause issues for users mounting directories in the Clara Train docker container.  This can be changed by setting


```
umask 0002
```


To make this persistent, add `umask 0002` to your user `~/.bashrc` configuration.  If there are existing files with restrictive permissions, you may need to run


```
chmod -R a+rX ~/*
```


If there are files with root ownership, e.g., from running other containers, you may need sudo in the above chmod command.

The Azure GPU-optimized image does not register the nvidia-container-runtime in `/etc/docker/daemon.json`.  While this isn’t strictly necessary for Docker versions >=19.03, it can cause errors in scripts that explicitly specify the runtime using `docker run --runtime=nvidia`.  To work around this, register the runtime in `/etc/docker/daemon.json` with:


```
    sudo tee /etc/docker/daemon.json <<EOF
    {
        "runtimes": {
            "nvidia": {
                "path": "/usr/bin/nvidia-container-runtime",
                "runtimeArgs": []
            }
        }
    }
    EOF
    sudo pkill -SIGHUP dockerd
```


The default Azure OS disk does not provide enough free space for the Docker data store, so we will instead use the large scratch disk provided with the instance.  In a production scenario, a more permanent disk should be used.  To use this scratch space, first create a directory:

	`sudo mkdir /mnt/docker`

And then edit `/etc/docker/daemon.json` to include the data-root directory:


```
    {
        "data-root": "/mnt/docker",
        "runtimes": { 
            "nvidia": {
                "path": "/usr/bin/nvidia-container-runtime",
                "runtimeArgs": []
            }
        }
    }
```



## Getting Started with Clara Train

Users new to the Clara Train SDK will benefit from the Jupyter Notebooks contained in the [Intro to Clara Train SDK](https://ngc.nvidia.com/catalog/resources/nvidia:med:clara:getting_started) collection, which walks through the basic user environment and provides scripts to pull and run the Docker image.  This collection will be used for the purpose of demonstration here.  Users already experienced with the Clara Train SDK may start directly with the [NVIDIA Clara Train SDK](https://ngc.nvidia.com/catalog/containers/nvidia:clara-train-sdk).

To get started with the [Intro to Clara Train SDK](https://ngc.nvidia.com/catalog/resources/nvidia:med:clara:getting_started) collection, ssh to the CSP instance, download and unzip, and start the Clara Train Docker container:


    ssh -i /path/to/identity.pem ubuntu@<IP of instance>
    # now on the cloud instance
    wget --content-disposition \
        https://api.ngc.nvidia.com/v2/resources/nvidia/med/getting_started/versions/1/zip \
        -O getting_started_1.zip
    unzip -d getting-started getting_started_1.zip
    cd getting-started/scripts && chmod a+x *.sh
    ./startDocker.sh 8890 '0' 5000

To access the services that will run in the Clara Train container, we will need the associated ports opened up to the cloud instance.  Using the examples in the Intro collection, we will need to open port 8890 for JupyterLab and port 5000 for AIAA.  These ports can be opened in the security settings for the cloud instance, for example in AWS Security Groups.  Another option is using SSH to forward these ports to your local machine:

    ssh -N -L localhost:8890:localhost:8890 \
        -L localhost:5000:localhost:5000 \
        <IP address of Cloud instance>

The `getting-started/readMe.md` provides an overview of the configuration and the basic steps required to get started.  Briefly, in this example, the `./startDocker.sh 8890 '0' 5000 `command above starts the container with JupyterLab configured to use port 8890, using GPU ‘0’, with AIAA services on port 5000.  Once working in the running container, the JupyterLab services are installed and started by running:

    installDashBoardInDocker.sh

This will produce output during installation of dependencies and finish with a message similar to the following:
 
    To access the notebook, open this file in a browser:
        file:///root/.local/share/jupyter/runtime/nbserver-613-open.html
    Or copy and paste one of these URLs:
        http://hostname:8888/?token=43dcac32bc4b939084db6cdaa047ef8b9771c97b8455c627

Note that the preceding output displays the default JupyterLab port 8888.  We have configured the container to expose this externally on port 8890.  With ports opened in the instance configuration or forwarded via SSH, you can then access JupyterLab by navigating to either `http://<instance IP address>:8890` or `http://localhost:8890`, respectively.  You will then be prompted in the JupyterLab interface for the token provided in the preceding output.  After successfully authenticating with this token, you can use the Welcome.ipynb notebook to get started with the Clara Train SDK.
