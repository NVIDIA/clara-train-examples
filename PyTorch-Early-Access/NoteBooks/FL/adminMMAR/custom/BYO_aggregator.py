
# SPDX-License-Identifier: Apache-2.0

import numpy as np

from fed_learn.numproto import proto_to_ndarray, ndarray_to_proto
from fed_learn.server.model_aggregator import Aggregator
from fed_learn.model_meta import FLContext


class CustomModelAggregator(Aggregator):
    def process(self, accumulator: [FLContext], fl_ctx: FLContext):
        """Aggregate the contributions from all the submitted FL clients.

        For the FLContext type we can use get_model() method to get the model data.
        The model data is a protobuf message and its format is defined as below.

        // A model consists of multiple tensors
        message ModelData {
            map<string, NDArray> params = 1;
        }

        // NDArray data for protobuf
        message NDArray {
          bytes ndarray = 1;
        }

        In this aggregation method we are using local number of iterations to weight each
        contribution and get a weighted average of that to be our new value.

        This function is not thread-safe.

        :param accumulator: List of all the contributions in FLContext.
        :param fl_ctx: An instance of FLContext.
        :return: Return True to indicates the current model is the best model so far.
        """
        # The model data is in model.params as a dict.
        model = fl_ctx.get_model()
        vars_to_aggregate = [set(item.get_model().params) for item in accumulator]
        vars_to_aggregate = set.union(*vars_to_aggregate)

        for v_name in vars_to_aggregate:
            n_local_iters, np_vars = [], []
            for item in accumulator:
                data = item.get_model()
                if v_name not in data.params:
                    continue  # this item doesn't have the variable from client

                # contribution is a protobuf msg
                #   it has `n_iter` which represents number of local iterations 
                #   used to compute this contribution 
                acc = item.get_prop('_contribution')
                float_n_iter = np.float(acc.n_iter)
                n_local_iters.append(float_n_iter)

                # weighted using local iterations
                weighted_value = proto_to_ndarray(data.params[v_name]) * float_n_iter
                np_vars.append(weighted_value)
            if not n_local_iters:
                continue  # didn't receive this variable from any clients
            new_val = np.sum(np_vars, axis=0) / np.sum(n_local_iters)
            new_val += proto_to_ndarray(model.params[v_name])

            # Update the params in model using CopyFrom because it is a ProtoBuf structure
            model.params[v_name].CopyFrom(ndarray_to_proto(new_val))
        return False
