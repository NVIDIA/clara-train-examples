# Description

A pre-trained model for automated detection of metastases in whole-slide histopathology images. The prediction map is generated in a sliding-window manner by classifying local 224x224x3 RGB patches as either tumor or normal.

# Model Overview

The model is based on ResNet18 with the last fully connected layer replaced by a 1x1 convolution layer.

## Data

All the data used to train, validate, and test this model is from [Camelyon-16 Challenge](https://camelyon16.grand-challenge.org/). You can download all the images for "CAMELYON16 data set" from various sources listed [here](https://camelyon17.grand-challenge.org/Data/).
Location information for training/validation patches are adopted from [NCRF/coords](https://github.com/baidu-research/NCRF/tree/master/coords).
Anotation information are adopted from [NCRF/jsons](https://github.com/baidu-research/NCRF/tree/master/jsons).

### Data Preparation

- For training/valiation: 0_train_loclabel_gen.sh is used to generate the LocLable files needed for training and validation from /coords and /jsons listed above. It will append the labels after each filename + coordinate pairs. Together with training images, they will be passed to training/validation pipeline.
- For inference: 1_test_foreground_mask.sh is used to generate foreground masks that will be used to reduce computation burden during inference. The input is the test images, and output is the foreground masks.
- For FROC: refer to "Annotation" section of [Camelyon challenge](https://camelyon17.grand-challenge.org/Data/) to prepare ground truth images, which are needed for FROC computation.

## Training configuration

## Input and output formats

Input for the training pipeline includes: 1) a folder containing all WSIs; and 2) txt files listing the location and label information for training patches.

Output of the network itself is the probability of a 224x224x3 patch.

For training/valiation: 0_train_loclabel_gen.sh is used to generate the LocLable files needed for training and validation from /coords and /jsons listed above. It will append the labels after each filename + coordinate pairs. Together with training images, they will be passed to training/validation pipeline.

## Inference on a WSI

Inference is performed on WSI in a sliding window manner with specified stride. A foreground mask is needed to specify the region where the inference will be performed on, given that background region which contains no tissue at all can occupy a significant portion of a WSI. Output of the inference pipeline is a probability map of size 1/stride of original WSI size.

## Scores

This model achieve the ~0.92 accuracy on validation patches, and FROC of ~0.72 on the 48 Camelyon testing data that have ground truth annotations available.

# Availability

In order to access this model please apply for general access:

https://developer.nvidia.com/clara

This model is usable only as part of Transfer Learning & Annotation Tools in Clara Train SDK container. You can download the model from NGC registry as described in Getting Started Guide

# Disclaimer

This is an example, not to be used for diagnostic purposes.