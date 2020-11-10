
# SPDX-License-Identifier: Apache-2.0

import logging
from fed_learn.client.fed_privacy import PrivacyProtocol
import numpy as np

class MyPrivacyProtocol(PrivacyProtocol):

    def __init__(self, percentile=10, gamma=0.01):
        self.logger = logging.getLogger('---- my Pricavy protocol')

        PrivacyProtocol.__init__(self)

    def apply(self, model_diff, train_ctx=None):
        self.logger.info("----------------")
        self.logger.info("-------client applying privacy---------")
        self.logger.info("----------------")
        """
        :param model_diff: model after a round of local training
        :param train_ctx: unused param.
        :return: model data to be uploaded to the server
        """

        # invariant to local steps
        scale = np.float(train_ctx.total_steps)
        delta_w = {name: model_diff[name] / scale for name in model_diff}

        return delta_w

class MyRandomProtocol(PrivacyProtocol):
    """
    Randomly drop some gradients
    """

    def __init__(self, percentage=10, gamma=0.01, non_zero_only=True):
        self.logger = logging.getLogger('RandomProtocol')

        PrivacyProtocol.__init__(self)
        # must be in 0..100, only update abs diff greater than percentile
        self.percentage = percentage
        assert percentage >= 0 & percentage <= 100, "select a percentage between 0 and 100!"

    def apply(self, model_diff, train_ctx=None):
        delta_w = {}
        n_removed = 0
        n_total = 0
        for name in model_diff:
            diff = model_diff[name]
            n = np.size(diff)
            n_total += n
            n_select = int(np.floor(n*self.percentage/100))
            if n_select > 0:
                idx = np.arange(n)
                select = np.random.choice(idx, size=n_select, replace=False)
                np.put(diff, select, v=0.0)  # set the randomly selected gradients to zero
                n_removed += n_select
            delta_w[name] = diff

        self.logger.info(f'Removed {n_removed} of {n_total} ({100*n_removed/n_total:.2f}%) parameters.')
        return delta_w
