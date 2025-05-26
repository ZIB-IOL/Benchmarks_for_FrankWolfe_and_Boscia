import os
import sys
import time
from typing import List, Optional, Tuple
import platform

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

        # Translate python dict to julia dict with symbol keys
        build_args_dict = self.jl.Dict()
        for key, value in self.config.build_args.items():
            build_args_dict[self.jl.Symbol(key)] = value

        fw_kwargs_dict = self.jl.Dict()
        for key, value in self.config.fw_kwargs.items():
            fw_kwargs_dict[self.jl.Symbol(key)] = value

        self.build_args = build_args_dict
        self.fw_kwargs = fw_kwargs_dict

        self.seed = self.config.seed
        self.time_per_run = self.config.time_per_run
        self.num_runs = self.config.num_runs

        # Import BenchmarksFWnB in local julia module
        self.jl.seval("using Pkg")
        self.jl.Pkg.activate(".")
        self.jl.seval("using BenchmarksFWnB")
    def log_metrics(self):
        log_dict = dict(
            computer=self.config.computer,
            fw_variant=self.config.fw_variant,
            problem=self.config.problem,
            build_args=self.config.build_args,
            fw_kwargs=self.config.fw_kwargs,
            seed=self.config.seed,
        )
        wandb.log(log_dict)


    def run(self):
        if self.package == "FrankWolfe":
            print("We got to FrankWolfe")
        elif self.package == "Boscia":
            print("We got to Boscia")
        else:
            raise ValueError(f"Invalid package to benchmark: {self.package}")