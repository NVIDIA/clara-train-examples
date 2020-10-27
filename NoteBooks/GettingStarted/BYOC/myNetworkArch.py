import tensorflow as tf
from ai4med.components.models.model import Model
import tensorflow.contrib.slim as slim

class CustomNetwork(Model):

    def __init__(self, num_classes,factor=32,
                 training=False,data_format='channels_first',
                 final_activation='linear'):
        Model.__init__(self)
        self.model = None
        self.num_classes = num_classes
        self.factor = factor
        self.training = training
        self.data_format = data_format
        self.final_activation = final_activation

        if data_format == 'channels_first':
            self.channel_axis = 1
        elif data_format == 'channels_last':
            self.channel_axis = -1

    def network(self, inputs, training, num_classes, factor, data_format, channel_axis):
        # very shallow Unet Network
        with tf.variable_scope('CustomNetwork'):

            conv1_1 = tf.keras.layers.Conv3D(factor, 3, padding='same', data_format=data_format, activation='relu')(inputs)
            conv1_2 = tf.keras.layers.Conv3D(factor * 2, 3, padding='same', data_format=data_format, activation='relu')(conv1_1)
            pool1 = tf.keras.layers.MaxPool3D(pool_size=(2, 2, 2), strides=2, data_format=data_format)(conv1_2)

            conv2_1 = tf.keras.layers.Conv3D(factor * 2, 3, padding='same', data_format=data_format, activation='relu')(pool1)
            conv2_2 = tf.keras.layers.Conv3D(factor * 4, 3, padding='same', data_format=data_format, activation='relu')(conv2_1)

            unpool1 = tf.keras.layers.UpSampling3D(size=(2, 2, 2), data_format=data_format)(conv2_2)
            unpool1 = tf.keras.layers.Concatenate(axis=channel_axis)([unpool1, conv1_2])

            conv7_1 = tf.keras.layers.Conv3D(factor * 2, 3, padding='same', data_format=data_format, activation='relu')(unpool1)
            conv7_2 = tf.keras.layers.Conv3D(factor * 2, 3, padding='same', data_format=data_format, activation='relu')(conv7_1)

            output = tf.keras.layers.Conv3D(num_classes, 1, padding='same', data_format=data_format)(conv7_2)

            if str.lower(self.final_activation) == 'softmax':
                output = tf.nn.softmax(output, axis=channel_axis, name='softmax')
            elif str.lower(self.final_activation) == 'sigmoid':
                output = tf.nn.sigmoid(output, name='sigmoid')
            elif str.lower(self.final_activation) == 'linear':
                pass
            else:
                raise ValueError(
                    'Unsupported final_activation, it must of one (softmax, sigmoid or linear), but provided:' + self.final_activation)
        model_vars = tf.trainable_variables()
        slim.model_analyzer.analyze_vars(model_vars, print_info=True)

        return output

    # additional custom loss
    def loss(self):
        return 0

    def get_predictions(self, inputs, training, build_ctx=None):
        self.model = self.network(inputs=inputs,training=training,num_classes=self.num_classes
                                  ,factor=self.factor,data_format=self.data_format,channel_axis=self.channel_axis)
        return self.model

    def get_loss(self):
        return self.loss()
