
# SPDX-License-Identifier: Apache-2.0

import tensorflow as tf
from ai4med.components.losses.loss import Loss

class MyClonedDiceLoss(Loss):

    def __init__(self,data_format='channels_first',skip_background=False,squared_pred=False,
                 jaccard=False,smooth=1e-5,top_smooth=0.0,is_onehot_targets=False
                 # , label_weights=None #
                 ):
        Loss.__init__(self)
        self.data_format = data_format
        self.skip_background = skip_background
        self.squared_pred = squared_pred
        self.jaccard = jaccard
        self.smooth = smooth
        self.top_smooth = top_smooth
        self.is_onehot_targets = is_onehot_targets
        # self.label_weights = label_weights

    def get_loss(self, predictions, targets, build_ctx=None):
        return dice_loss(predictions, targets,
                         data_format=self.data_format,
                         skip_background=self.skip_background,
                         squared_pred=self.squared_pred,
                         jaccard=self.jaccard,
                         smooth=self.smooth,
                         top_smooth=self.top_smooth,
                         is_onehot_targets=self.is_onehot_targets
                         # , label_weights=self.label_weights
                         )

def dice_loss(predictions,
              targets,
              data_format='channels_first',
              skip_background=False,
              squared_pred=False,
              jaccard=False,
              smooth=1e-5,
              top_smooth=0.0,
              is_onehot_targets=False):

    is_channels_first = (data_format == 'channels_first')
    ch_axis = 1 if is_channels_first else -1

    n_channels_pred = predictions.get_shape()[ch_axis].value
    n_channels_targ = targets.get_shape()[ch_axis].value
    n_len = len(predictions.get_shape())

    print('dice_loss targets', targets.get_shape().as_list(),
          'predictions', predictions.get_shape().as_list(),
          'targets.dtype', targets.dtype,
          'predictions.dtype', predictions.dtype)

    print('dice_loss is_channels_first:', is_channels_first,
          'skip_background:', skip_background,
          'is_onehot_targets', is_onehot_targets)

    # Sanity checks
    if skip_background and n_channels_pred == 1:
        raise ValueError("There is only 1 single channel in the predicted output, and skip_zero is True")
    if skip_background and n_channels_targ == 1 and is_onehot_targets:
        raise ValueError("There is only 1 single channel in the true output (and it is is_onehot_true), "
                         "and skip_zero is True")
    if is_onehot_targets and n_channels_targ != n_channels_pred:
        raise ValueError("Number of channels in target {} and pred outputs {} "
                         "must be equal to use is_onehot_true == True".format(
                            n_channels_targ, n_channels_pred))

    # End sanity checks
    if not is_onehot_targets:
        # if not one-hot representation already
        # remove singleton (channel) dimension for true labels
        targets = tf.cast(tf.squeeze(targets, axis=ch_axis), tf.int32)
        targets = tf.one_hot(targets, depth=n_channels_pred, axis=ch_axis,
                             dtype=tf.float32, name="loss_dice_targets_onehot")

    if skip_background:
        # if skipping background, removing first channel
        targets = targets[:, 1:] if is_channels_first else targets[..., 1:]
        predictions = predictions[:, 1:] if is_channels_first else predictions[..., 1:]
        # uncomment lines below for exercise #1
        # if label_weights is not None:
        #     label_weights = label_weights[1:]

    # reducing only spatial dimensions (not batch nor channels)
    reduce_axis = list(range(2, n_len)) if is_channels_first else list(range(1, n_len - 1))

    intersection = tf.reduce_sum(targets * predictions, axis=reduce_axis)

    # uncomment lines below for exercise #1
    # if label_weights is not None:  # add wights to labels
    #     print("========== debug research intersection.shape=", intersection.shape)
    #     w = tf.constant(label_weights, dtype=tf.float32)
    #     intersection = tf.multiply(w, intersection)


    if squared_pred:
        # technically we don't need this square for binary true values
        # (but in cases where true is probability/float, we still need to square
        targets = tf.square(targets)
        predictions = tf.square(predictions)

    y_true_o = tf.reduce_sum(targets, axis=reduce_axis)
    y_pred_o = tf.reduce_sum(predictions, axis=reduce_axis)

    denominator = y_true_o + y_pred_o

    if jaccard:
        denominator -= intersection
    f = (2.0 * intersection + top_smooth) / (denominator + smooth)
    f = tf.reduce_mean(f)  # final reduce_mean across batches and channels
    return 1 - f

