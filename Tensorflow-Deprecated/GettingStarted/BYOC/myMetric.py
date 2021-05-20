
# SPDX-License-Identifier: Apache-2.0

import numpy as np
from ai4med.components.metric import Metric
from ai4med.libs.metrics.metric_list import MetricList


class SampleMetricAverage(MetricList):
    """
    Generic class for tracking averages of metrics. Expects that the elements in self._list
    are scalar values that will be averaged
    """
    def __init__(self, name, invalid_value=float('nan'), report_path=None):
        MetricList.__init__(self, name,
                            invalid_value=invalid_value,
                            report_path=report_path)

    def get(self):
        if self._list is None or self._list.size == 0:
            return 0

        return np.mean(self._list)

class SampleComputeAverage(Metric):

    def __init__(self, name, field,
                 invalid_value=float('nan'),
                 report_path=None,
                 do_summary=True,
                 do_print=True,
                 is_key_metric=False):

        m = SampleMetricAverage(name, invalid_value, report_path)

        Metric.__init__(self, m,
                        field=field,
                        do_summary=do_summary,
                        do_print=do_print,
                        is_key_metric=is_key_metric)
