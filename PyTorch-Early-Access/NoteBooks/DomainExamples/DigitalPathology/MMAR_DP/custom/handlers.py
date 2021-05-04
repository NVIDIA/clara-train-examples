import logging
import os
from typing import TYPE_CHECKING, Optional

import numpy as np
import matplotlib.pyplot as plt
from skimage import filters
from monai.utils import exact_version, optional_import

Events, _ = optional_import("ignite.engine", "0.4.2", exact_version, "Events")
if TYPE_CHECKING:
    from ignite.engine import Engine
else:
    Engine, _ = optional_import("ignite.engine", "0.4.2", exact_version, "Engine")


class ProbMapSaver:
    """
    Event handler triggered on completing every iteration to save the probability map
    """

    def __init__(
        self,
        output_dir: str = "./",
        filename: str = None,
        name: Optional[str] = None,
    ) -> None:
        """
        Args:
            output_dir: output Numpy and CSV file directory.
            overwrite: whether to overwriting existing CSV file content. If we are not overwriting,
                then we check if the results have been previously saved, and load them to the prediction_dict.
            name: identifier of logging.logger to use, defaulting to `engine.logger`.

        """
        self.logger = logging.getLogger(name)
        self._name = name
        self.output_dir = output_dir
        self.probs_maps = {}
        self.levels = {}
        self.case_names = []

    def attach(self, engine: Engine) -> None:
        """
        Args:
            engine: Ignite Engine, it can be a trainer, validator or evaluator.
        """

        for name, info in engine.data_loader.dataset.info.items():
            self.case_names.append(name)
            self.probs_maps[name] = np.zeros(info['mask_dims'])
            self.levels[name] = info['level']

        if self._name is None:
            self.logger = engine.logger
        if not engine.has_event_handler(self, Events.ITERATION_COMPLETED):
            engine.add_event_handler(Events.ITERATION_COMPLETED, self)
        if not engine.has_event_handler(self.finalize, Events.COMPLETED):
            engine.add_event_handler(Events.COMPLETED, lambda engine: self.finalize())

    def __call__(self, engine: Engine) -> None:
        """
        This method assumes self.batch_transform will extract metadata from the input batch.

        Args:
            engine: Ignite Engine, it can be a trainer, validator or evaluator.
        """
        names = engine.state.batch['name']
        locs = engine.state.batch['location']
        preds = engine.state.output['pred']
        for i, name in enumerate(names):
            self.probs_maps[name][locs[0][i], locs[1][i]] = preds[i]

    def finalize(self):
        for name in self.case_names:
            file_path = os.path.join(self.output_dir, name)
            np.save(file_path + '.npy', self.probs_maps[name])
            plt.imshow(np.transpose(self.probs_maps[name]))
            plt.savefig(file_path + '.png')
            self.nms(self.probs_maps[name], file_path, level=self.levels[name])

    def nms(self, probs_map, file_path, level, sigma=0.0, prob_thred=0.5, radius=24):
        if sigma > 0:
            probs_map = filters.gaussian(probs_map, sigma=sigma)

        x_shape, y_shape = probs_map.shape
        resolution = pow(2, level)

        with open(file_path + '.csv', 'w') as outfile:
            while np.max(probs_map) > prob_thred:
                prob_max = probs_map.max()
                max_idx = np.where(probs_map == prob_max)
                x_mask, y_mask = max_idx[0][0], max_idx[1][0]
                x_wsi = int((x_mask + 0.5) * resolution)
                y_wsi = int((y_mask + 0.5) * resolution)
                outfile.write('{:0.5f},{},{}'.format(prob_max, x_wsi, y_wsi) + '\n')

                x_min = x_mask - radius if x_mask - radius > 0 else 0
                x_max = x_mask + radius if x_mask + radius <= x_shape else x_shape
                y_min = y_mask - radius if y_mask - radius > 0 else 0
                y_max = y_mask + radius if y_mask + radius <= y_shape else y_shape

                for x in range(x_min, x_max):
                    for y in range(y_min, y_max):
                        probs_map[x, y] = 0
