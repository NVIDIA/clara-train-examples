
# SPDX-License-Identifier: Apache-2.0

from monai.transforms.transform import MapTransform
from typing import Any, Dict, Hashable, Mapping, Optional, Sequence, Tuple, Union
import numpy as np
import pyprof
pyprof.init(enable_function_stack=True)

class DlprofDummy(MapTransform):
    def __init__(self):
        print ("______________________")
        print ("________in Dlprof init______________")
        pass

    def __call__(self, data: Mapping[Union[Hashable, str], Dict[str, np.ndarray]]
        ) -> Dict[Union[Hashable, str], Union[np.ndarray, Dict[str, np.ndarray]]]:

        return data
