import os
import sys
import time
from typing import List, Optional, Tuple
import platform
from contextlib import redirect_stdout
import io

import juliacall

import wandb

class Runner:
    # Runner class to run the benchmark with wandb
    def __init__(self, config, tmp_dir, debug):

        self.config = config
        self.tmp_dir = tmp_dir
        self.debug = debug

        self.is_htc = 'htc-' in platform.uname().node                                               # True if we are running on the HTC cluster
        self.is_coder = 'coder' in platform.uname().node and 'workspace' in platform.uname().node   # True if we are running on the coder workspace

        self.jl = juliacall.newmodule('Main')

        self.package = self.config.package
        self.fw_variant = self.config.fw_variant
        self.problem = self.config.problem

        # Import BenchmarksFWnB in local julia module
        self.jl.seval("using Pkg")
        self.jl.Pkg.activate(".")
        self.jl.Pkg.update()
        self.jl.seval("using BenchmarksFWnB")
        if self.package == "FrankWolfe":
            self.jl.seval("using FrankWolfe")
        elif self.package == "Boscia":
            self.jl.seval("using Boscia")

        # Translate python dict to julia dict with symbol keys
        if isinstance(self.config.build_args, str):
            self.build_args = self.config.build_args #self.jl.seval(self.config.build_args)
        else:
            self.build_args = self.config.build_args
            build_args_dict = self.jl.Dict()
            for key, value in self.build_args.items():
                try:
                    build_args_dict[self.jl.Symbol(key)] = self.jl.seval(value)
                except:
                    build_args_dict[self.jl.Symbol(key)] = self.jl.eval(value)
            self.build_args = build_args_dict

        if isinstance(self.config.kwargs, str):
            self.fw_kwargs = self.config.kwargs #self.jl.seval(self.config.kwargs)
        else:  # TODO: fix passing of python dicts to julia. Currently passing e.g. dict(line_search="FrankWolfe.Secant()") fails due to unknown reasons.
            self.kwargs = self.config.kwargs
            kwargs_dict = self.jl.Dict()
            for key, value in self.kwargs.items():
                try:
                    kwargs_dict[self.jl.Symbol(key)] = self.jl.seval(value)
                except:
                    kwargs_dict[self.jl.Symbol(key)] = self.jl.eval(value)
            self.kwargs = kwargs_dict

        # sys.stdout.write(f"kwargs: {self.fw_kwargs}\n")
        # sys.stdout.flush()

        self.seed = self.config.seed
        self.time_per_run = self.config.time_per_run
        self.num_runs = self.config.num_runs


    def log_metrics(self):
        log_dict = dict(
            computer=self.config.computer,
            fw_variant=self.config.fw_variant,
            problem=self.config.problem,
            build_args=self.config.build_args,
            fw_kwargs=self.config.kwargs,
            seed=self.config.seed,
        )
        wandb.log(log_dict)


    def run(self):
        if self.package == "FrankWolfe":
            self.jl.seval(f"n = {self.build_args}[:n]")
            self.jl.seval(f"log_name = \"{self.package}_{self.fw_variant}_{self.problem}_n$n_{self.seed}.txt\"")
            self.jl.seval(f"f = open(log_name, \"w\")")
            bm, obj_counts, grad_counts, lmo_counts, dual_gaps, memory, times = self.jl.seval(f"""redirect_stdout(f) do 
                return benchmark_FW(
                        fw=\"BPCG\",
                        problem=\"Simplex\",
                        build_args={self.build_args},
                        seed={self.seed},
                        fw_kwargs={self.kwargs},
                        num_runs={self.num_runs},
                        time_per_run={self.time_per_run},
                    )
            end""")
            self.jl.seval("write(f, \"\n\")")
            self.jl.seval(f"close(f)")

        elif self.package == "Boscia":
            print("We got to Boscia")
        else:
            raise ValueError(f"Invalid package to benchmark: {self.package}")