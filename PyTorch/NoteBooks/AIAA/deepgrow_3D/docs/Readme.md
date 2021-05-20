DeepGrow 3D Readme

# Model Overview
The best results are expected on the abdomen organs that this model was trained upon, which is mentioned in the Data section. The model maybe applicable to unseen organs and unseen data however the performance of the annotation is not guaranteed.

## Data
The training data is from the MICCAI 2015 Challenge: Multi-Atlas Labeling Beyond The Cranial Vault. Link to the challenge data: https://www.synapse.org/#!Synapse:syn3193805/wiki/217789 The dataset has 13 labeled organs and all organs were utilized for training this model. Further details about the data can be found at the aforementioned link.

The data must be converted to 1mm x 1mm x 3mm resolution before training


Run `sh prepare_dataset.sh --help` from *MMAR/commands folder to know more options to prepare the dataset for training

## Training Configuration
The current training configuration apart from traditional deep learning hyper-parameters is set for 15 click interactions for both training and validation. Click interactions define how many positive and negative clicks are provided for the additional feature maps in simulation before a single step/iteration is taken for the deep learning model for a batch of images. Single and multi-GPU training options are available. 

The training utilizes patches of 128x128x128 which are extracted based on the label for the training process. The positive and negative click maps are automatically handled internally.

## Scores
Achieves Dice scores of ~0.84 and ~0.85 for training and validation on a 80/20 split. Further testing was performed on medical segmentation decathlon dataset on a random selection of 10 volumes the following Dice scores were achieved. ~0.95 on Spleen

# Availability
In order to access this model please apply for general access:

https://developer.nvidia.com/clara

This model is usable only as part of Transfer Learning & Annotation Tools in Clara Train SDK container. You can download the model from NGC registry as described in Getting Started Guide

# Disclaimer
This is an example, not to be used for diagnostic purposes.

# References
[1] Landman, B., et al. "Multi-atlas labeling beyond the cranial vault." URL: https://www. synapse. org (2015).
[2] Sakinis, Tomas, et al. "Interactive segmentation of medical images through fully convolutional neural networks." arXiv preprint arXiv:1903.08205 (2019).
