
# SPDX-License-Identifier: Apache-2.0

import numpy as np

# note the ai4med here
# from ai4med.common.medical_image import MedicalImage
# from ai4med.common.transform_ctx import TransformContext
from ai4med.components.transforms.multi_field_transformer import MultiFieldTransformer

# from ai4med.components.transforms.scale_intensity_range import ScaleIntensityRange
# class MyScaleIntensityRange(ScaleIntensityRange):
#     def __init__(self,fields, a_min, b_min, a_max=None, b_max=None, clip=False,a_offset=0,b_offset=None, dtype='float32'):
#         if a_offset is not None:
#             a_max=a_min+a_offset
#         if b_offset is not None:
#             b_max=b_min+b_offset
#         assert isinstance(a_offset, (int, float)) , "------AEH why is this not working "
#         ScaleIntensityRange.__init__(self,fields, a_min, a_max, b_min, b_max, clip,dtype=dtype)

class MyAddRandomConstant(MultiFieldTransformer):

    def __init__(self, fields, magnitude, dtype=np.float32):
        # fields specifies the names of the image fields in the data dict that you want to add constant to
        MultiFieldTransformer.__init__(self, fields)
        self.dtype = dtype
        self.magnitude = magnitude

    def transform(self, transform_ctx):
        for field in self.fields:
            offset = (np.random.rand() * 2.0 - 1.0) * self.magnitude
            # get the MedicalImage using field
            img = transform_ctx.get_image(field)

            # get_data give us a numpy array of data
            result = img.get_data() + offset

            # create a new MedicalImage use new_image() method
            # which will carry over the properties of the original image
            result_img = img.new_image(result, img.get_shape_format())

            # set the image back in transform_ctx
            transform_ctx.set_image(field, result_img)
        return transform_ctx

    def is_deterministic(self):
        # This is not a deterministic transform.
        return False
