# Dicom Demo

This tutorial walks you through  

There are multiple notebooks:
1. [Concepts](content/1 Concepts.ipynb)
2. [DICOM](content/2 DICOM.ipynb)
3. [DICOMweb](content/3 DICOMweb.ipynb)

# Installation

1. Clone this repo
2. Run `buildDockerImage.sh` to build docker image 
3. Run `startDocker.sh` to start the jupyterlab on port `8888`
4. Once the container is running, visit the content in your browser: `http://localhost:8888`  


# Cleanup
to stop container you should run 
```
docker stop dicom-demo
```
