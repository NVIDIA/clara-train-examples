# Description
A pre-trained model for deepgrow 3D.

# Model Overview
TODO

## Data
The training dataset is xyz.tar from abc.

The data must be converted to 1mm resolution before training, or use MONAI `Spacing` transform.

NOTE: to match up with the default setting, we suggest that ${DESTINATION_IMAGE_ROOT} match DATA_ROOT as defined in environment.json in this MMAR's config folder.

## Training configuration
The training was performed with command train.sh, which required 12GB-memory GPUs.

Actual Model Input: 128 x 128 x 128

## Input and output formats
Input: 2 channel CT image

Output: 1 channels: Label 1: segmentation; Label 0: everything else

## Scores
This model achieve the following Dice score on the validation data (our own split from the training dataset):

1. Spleen: TODO

# Availability
In order to access this model please apply for general access:

https://developer.nvidia.com/clara

This model is usable only as part of Transfer Learning & Annotation Tools in Clara Train SDK container. You can download the model from NGC registry as described in Getting Started Guide

# Disclaimer
This is an example, not to be used for diagnostic purposes

# References
[1] TODO.
