<!--- SPDX-License-Identifier: Apache-2.0 -->

# Notebooks for Clara Train SDK 

This is a set of multiple notebooks which walks you through Clara train SDK features and capabilities.  
There are multiple notebooks showing:
- Performance gains
- Hyper parameter optimization with AutoML
- Federated learning features
- Domain specific examples
- Assisted annotation   

# List of Notebooks

1. Getting Started 
    1. [Getting Started](GettingStarted/GettingStarted.ipynb)
    1. [Bring your own component BYOC](GettingStarted/BYOC.ipynb)
2. AI Assisted Annotation (AIAA):
    1. [Basics](AIAA/AIAA.ipynb)
    2. [Train Deepgrow (2D and 3D)](AIAA/DeepGrow.ipynb)
    3. [OHIF](AIAA/AIAAwOHIF.ipynb)
3. DataSets
    1. [Download Decathlon Dataset](Data/DownloadDecathlonDataSet.ipynb)<br>
    2. [Download from National Cancer Archive](Data/TCIA/TCIADownloader.ipynb)<br>
4. Federated Learning <br>
    1. [Federated learning](FL/FederatedLearning.ipynb) 
    2. [Provisioning Notebook](FL/Provisioning.ipynb) 
    3. [Client Notebook](FL/Client.ipynb) 
    4. [Administration of FL experiment](FL/Admin.ipynb) 
    5. [Bring your own Component to FL](FL/Admin_BYOC.ipynb) 
5. AutoML
    1. [AutoML Basics](AutoML/AutoML.ipynb)
    1. <del>[AutoML BYOC](AutoML/AutoML_BYOC.ipynb)</del>
6. [Digital pathology](DomainExamples/DP_detection/DP.ipynb)
7. Integration 
    1. <del>[End to End workflow](DomainExamples/End2End/End2End.ipynb)</del>
    2. <del>[Train to Deploy](DomainExamples/Train2Deploy/Train2Deploy.ipynb)</del>


## Pre-requisites 

1. One or more Nvidia GPU. (2+GPUS are recommended for advanced features as AutoML).
2. If you already have docker installed then user should be in the docker group. 
Otherwise, sudo is needed to install the pre requisite 
 
This NoteBooks contain:

1. Scripts to: 
    1. Install pre-requisite as Docker 19, docker compose  
    2. Start pulling the clara docker and run jupyter lab.
3. SampleData: To start using the sdk.
3. Multiple Notebooks to show show all capabilities of the sdk

# Getting started 

## 1. Install cuda nvidia drivers / Trouble Shooting Cuda

You should skip this step, if you already have cuda and nvida driver. 
To check simply run
`nvidia-smi`  

If you don't have nvidia drivers / cuda installed or you do get a cuda lib mismatch when running `nvidia-smi`
as 
```
nvidia-smi
Failed to initialize NVML: Driver/library version mismatch
```
then you need to do the following steps 
##### 1.1- Remove drivers
 ```
sudo apt-get --purge remove "*nvidia*"
sudo apt autoremove
```
##### 1.2- Reboot
reboot using 
```
sudo systemctl reboot
```
##### 1.3- Install cuda 
Got to https://developer.nvidia.com/cuda-11.0-download-archive?target_os=Linux
pick your os and hardware and follow instructions 
##### 1.4- Reboot again 
you need to reboot again after installing cuda  
```
sudo systemctl reboot
```
##### 1.5- check Nvidia-smi  
run `nvidia-smi` should show you the gpus you have on your system 

## 2. Install pre-req
If you already have docker 19+, nvidia docker, and docker compose you can skip this step. 
Otherwise, you can install docker and docker compose using script provided by  
```
cd scripts 
sudo installDocker.sh
```
## 3. Start Docker-Compose 

To begin, go into the scripts folder
          
       cd scripts

run command below which will pull and start the latest clara train SDK and Triton server for AIAA.
 
    ./restartClaraTrain.sh

You can now go to your browser on port 3030 and use the token printed out as below

    [I 23:47:18.654 LabApp] http://claratrain:8888/?token=3e5ef35f982ea5a3e432322b07b6d33b5fc51a4fcb0ffa88
    [I 23:47:18.654 LabApp]  or http://127.0.0.1:8888/?token=3e5ef35f982ea5a3e432322b07b6d33b5fc51a4fcb0ffa88

#### 3.1 Customize docker compose 

You should edit the docker-compose.yml file in case you want to:
- start jupter lab on different port than 3030
- change the AIAA port 
as 
```
    ports:
      - "3030:8888"  # Jupyter lab port 
      - "3031:5000"  # AIAA port
```

To expose certain gpus to Triton please uncomment lines at the end of the docker-compose file 

```
      capabilities: [ gpu ]
      # To specify certain GPU uncomment line below
      #device_ids: ['0,1']
```

Now you should be inside the docker as see output similar to
<br>
<img src="screenShots/startDocker.png" alt="drawing" width="600"/>

## 4. Open Browser with given token

Now you can go to your browser on the port you specified above (default is 3030) with the token provided in the terminal. 
You should see jupyter lab where you should start running the [Welcome Notebook](Welcome.ipynb). 
This page shows all notebooks available as 


## 5. Activating GPU Dashboard (optional)

Before starting, we need to activate the GPU Dashboard. 
Look at the left sidebar and click on `System Dashboards`. 
<br>
<img src="screenShots/left_side_bar.png" alt="drawing" width="300"/>


Next, click on `GPU Utilization`, `GPU Memory`,`GPU Resources`, and `MachineResources`. 
All of these will open in new tabs. 
Click and hold on `GPU Utilization` tab and drag it to the right most area of screen. 
It will dock the tab on top of the notebook. 
Follow the same procedure with `GPU Memory` tab and docker it on the bottom right of screen. 
The result should be similar to

<br>
<img src="screenShots/result.png" alt="drawing" width="600"/>

Now we can see GPU Utilization and GPU Memory while we run through the notebooks.
