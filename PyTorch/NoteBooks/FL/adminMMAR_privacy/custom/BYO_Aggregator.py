from typing import Tuple
from nvflare.apis.aggregator import Aggregator
from nvflare.apis.fl_constant import ShareableKey, ShareableValue
from nvflare.apis.fl_context import FLContext
from nvflare.apis.shareable import Shareable

"""
This example shows a aggregator that just does simple averaging of submitted
weight diffs from clients.
The accept method is called every time a client's submission is received;
The aggregate method is called at the end of the round after all submissions are received.
"""

class MyJustInTimeAggregator(Aggregator):

    def __init__(self):
        """Perform simple averaging aggregation
        """
        super().__init__()
        self.total = dict()
        self.counts = dict()

    def handle_event(self, event_type: str, fl_ctx: FLContext):
        return True

    def reset_stats(self):
        self.total = dict()
        self.counts = dict()

    def accept(self, shareable: Shareable, fl_ctx: FLContext) -> Tuple[bool, bool]:
        """Store shareable and update aggregator's internal state

        This method is called to accept a client's submitted training result (weight diff)

        Args:
            shareable: information from client. It contains weight diff
            fl_ctx: context provided by workflow. You can get name of the submitting client
            from this context, among other things.

        Returns:
            The first boolean indicates if this shareable is accepted.
            The second boolean indicates if aggregate can be called.
        """
        assert (
            shareable.get(ShareableKey.TYPE, None) == ShareableValue.TYPE_WEIGHT_DIFF
        ), f"{self._name} support weight difference type shareable only"
        assert (
            shareable.get(ShareableKey.DATA_TYPE, None) == ShareableValue.DATA_TYPE_UNENCRYPTED
        ), f"{self._name} support clear datatype shareable only"

        aggr_data = shareable[ShareableKey.MODEL_WEIGHTS]
        for k, v in aggr_data.items():
            current_total = self.total.get(k, None)
            if current_total is None:
                self.total[k] = v
                self.counts[k] = 1
            else:
                self.total[k] = current_total + v
                self.counts[k] = self.counts[k] + 1
        return True, False

    def aggregate(self, fl_ctx: FLContext) -> Shareable:
        """Called when workflow determines to generate shareable to send back to clients

        Args:
            fl_ctx (FLContext): context provided by workflow

        Returns:
            Shareable: the weighted mean of accepted shareables from clients
        """
        aggregated_dict = dict()
        for k, v in self.total.items():
            aggregated_dict[k] = v / self.counts[k]
        self.reset_stats()

        shareable = Shareable()
        shareable[ShareableKey.TYPE] = ShareableValue.TYPE_WEIGHT_DIFF
        shareable[ShareableKey.DATA_TYPE] = ShareableValue.DATA_TYPE_UNENCRYPTED
        shareable[ShareableKey.MODEL_WEIGHTS] = aggregated_dict
        return shareable
