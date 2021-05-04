
# SPDX-License-Identifier: Apache-2.0

from queue import PriorityQueue
from random import randint, uniform

from automl.components.controllers.controller import Controller
from automl.defs import Context, Recommendation, Outcome, SearchResult

from automl.components.handlers.handler import Handler
from automl.defs import Context, ContextKey, Status
import mlflow
import threading

class RandomController(Controller):
    def __init__(self, max_rounds=1000):
        Controller.__init__(self)
        self.current_rec_id = 0
        self.space = None
        self.ctx = None
        self.enum_space = None
        self.float_space = None
        self.enum_size = 0
        self.search_log = dict()
        self.score_priority_queue = PriorityQueue()
        self.max_rounds = max_rounds

    def set_search_space(self, space, ctx):

        self.space = space
        self.ctx = ctx
        self.enum_space = self._get_subspace('.enum')
        self.float_space = self._get_subspace('.float')
        enum_size = 1
        for k in self.enum_space:
            enum_size = enum_size * len(self.enum_space[k])
        self.enum_size = enum_size

    def _get_subspace(self, subspace_key):
        return {k: v for k, v in self.space.targets.items() if subspace_key in k}

    def _sample_space(self):
        # modify this to generate 2 options at once
        # returns recommends: list of recommendation to run at the same time
        recommends = list()
        for _ in range(self.max_rounds): # generate random samples
            values = dict()
            for k, v in self.enum_space.items():
                # print("in Enum space k,v=",k,v)
                target = randint(0,len(v)-1)
                values[k] = target
            for k, v in self.float_space.items():
                target = uniform(v[0].min, v[0].max)
                values[k] = target
            self._keep_log(values)
            sr = SearchResult(self.space, values)
            recommend = Recommendation(self.current_rec_id, sr)
            recommends.append(recommend)
            # TODO append another recommendation it will be sch automatically
            # print(" values", values)
            self.current_rec_id = self.current_rec_id + 1
        return recommends

    def initial_recommendation(self, ctx):
        recommends = self._sample_space()
        return recommends

    def _keep_log(self, values):
        self.search_log[self.current_rec_id] = dict()
        self.search_log[self.current_rec_id]['recommendation'] = values
        self.search_log[self.current_rec_id]['outcome'] = None

    def _update_log_with_outcome(self, rec_id, outcome):
        self.search_log[rec_id]['outcome'] = outcome

    def refine_recommendation(self, outcome: Outcome, ctx: Context):
        outcome_score = outcome.score
        outcome_rec_id = outcome.recommendation_id
        self.score_priority_queue.put((-outcome_score, outcome_rec_id))
        self._update_log_with_outcome(outcome_rec_id, outcome)
        if self.score_priority_queue.qsize() >= self.max_rounds:
            ctx.stop_work(self,"Number of runs reached {}.  Requesting stop.".format(self.max_rounds))
            return []
        recommends = self._sample_space()
        return recommends
###########################################################################################################
class MyHandler(Handler):

    def __init__(self):
        Handler.__init__(self)
        self.recs = list()
        self.update_lock = threading.Lock()

        # self.logger = logging.getLogger(self.__class__.__name__)
    def recommendations_available(self, ctx):
        recs = ctx.get_prop(ContextKey.RECOMMENDATIONS)
        print('recommendations available')
        for i, rec in enumerate(recs):
            self.recs.append(rec)
            # print('recommendation #{}'.format(i))
            # rec.result.dump()
            # print()
    def startup(self, ctx: Context):
        print(" __________starting up")
    def shutdown(self, ctx: Context):
        # print("__________shutdown")
        pass
    def start_job(self, ctx: Context):
        print("start job ")
        self.recommendations_available(ctx)
        print("______Job __name",ctx.get_prop("_jobName"),"________has______started")
        recomds=ctx.get_prop("_recommendations")

        pass
    def round_ended(self, ctx: Context):
        print("_________round_ended")
        pass
    def end_job(self, ctx: Context):

        print("_____________  end_job")
        job_name = ctx.get_prop(ContextKey.JOB_NAME)
        print("job name {}".format(job_name))
        parms = ctx.get_prop(ContextKey.CONCRETE_SEARCH_VALUE)
        # mlflow.start_run()
        mlflow.set_tracking_uri("/claraDevDay/AutoML/mlruns")
        with self.update_lock:
            with mlflow.start_run() as run:
                for k, v in parms.items():
                    par = k.split(":")[1]
                    v=v[0]
                    print("par=", par, " val=", v)
                    mlflow.log_param(par, v)
                score = ctx.get_prop(ContextKey.SCORE)
                print("score =",score)
                mlflow.log_metric("Acc", score)
                print ("MLFLOW added ")
                print("___________________________")
        # mlflow.end_run()

        return

###########################################################################################################
class MyHandler2(Handler):
    def __init__(self):
        Handler.__init__(self)
        pass
    def recommendations_available(self, ctx):
        pass
    def startup(self, ctx: Context):
        pass
    def shutdown(self, ctx: Context):
        pass
    def start_job(self, ctx: Context):
        pass
    def round_ended(self, ctx: Context):
        pass
    def end_job(self, ctx: Context):
        pass
###########################################################################################################
class RandomController2(Controller):
    def __init__(self, max_rounds=1000):
        Controller.__init__(self)
    def set_search_space(self, space, ctx):
        pass
    def initial_recommendation(self, ctx):
        pass
    def refine_recommendation(self, outcome: Outcome, ctx: Context):
        pass
