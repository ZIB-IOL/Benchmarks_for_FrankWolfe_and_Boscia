import os
import sys
import time
from typing import List, Optional, Tuple
import platform
from contextlib import redirect_stdout
import io

import juliacall
import matplotlib.pyplot as plt
import numpy as np

import wandb

class Runner:
    # Runner class to run the benchmark with wandb
    def __init__(self, config, tmp_dir, debug):

        self.config = config
        self.tmp_dir = tmp_dir
        self.debug = debug

        self.is_htc = 'htc-' in platform.uname().node                                               # True if we are running on the HTC cluster
        self.is_coder = 'coder' in platform.uname().node and 'workspace' in platform.uname().node   # True if we are running on the coder workspace
        self.name = self.config.name

        # Initialize julia
        self.jl = juliacall.newmodule('Main')

        self.package = self.config.package
        self.fw_variant = self.config.fw_variant
        self.problem = self.config.problem

        # Import BenchmarksFWnB in local julia module
        self.jl.seval("using Pkg")
        self.jl.Pkg.activate(".")
        self.jl.Pkg.instantiate()
        self.jl.seval("using BenchmarksFWnB")
        self.jl.seval("using FrankWolfe")
        if self.package == "Boscia":
            self.jl.seval("using Boscia")
        self.jl.seval("using DataFrames")
        self.jl.seval("using CSV")

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
            self.kwargs = self.config.kwargs #self.jl.seval(self.config.kwargs)
        else:  # TODO: fix passing of python dicts to julia. Currently passing e.g. dict(line_search="FrankWolfe.Secant()") fails due to unknown reasons.
            self.kwargs = self.config.kwargs
            kwargs_dict = self.jl.Dict()
            for key, value in self.kwargs.items():
                try:
                    kwargs_dict[self.jl.Symbol(key)] = self.jl.seval(value)
                except:
                    kwargs_dict[self.jl.Symbol(key)] = self.jl.eval(value)
            self.kwargs = kwargs_dict

        self.seed = self.config.seed
        self.time_per_run = self.config.time_per_run
        self.num_runs = self.config.num_runs
        self.settings_bnb = self.config.settings_bnb or self.jl.seval("Dict{Symbol, Any}()")
        self.settings_fw = self.config.settings_fw or self.jl.seval("Dict{Symbol, Any}()")
        self.settings_tol = self.config.settings_tol or self.jl.seval("Dict{Symbol, Any}()")
        self.settings_pp = self.config.settings_pp or self.jl.seval("Dict{Symbol, Any}()")
        self.settings_heur = self.config.settings_heur or self.jl.seval("Dict{Symbol, Any}()")
        self.settings_tight = self.config.settings_tight or self.jl.seval("Dict{Symbol, Any}()")
        self.settings_domain = self.config.settings_domain or self.jl.seval("Dict{Symbol, Any}()")
        self.settings_mode = self.config.settings_mode or self.jl.seval("Dict{Symbol, Any}()")  


    def log_metrics(self):
        log_dict = dict(
            Variant=self.config.fw_variant,
            Problem=self.config.problem,
            build_args=self.config.build_args,
            kwargs=self.config.kwargs,
            seed=self.config.seed,
        )
        if self.package == "Boscia":
            log_dict["settings_bnb"] = self.settings_bnb
            log_dict["settings_fw"] = self.settings_fw
            log_dict["settings_tol"] = self.settings_tol
            log_dict["settings_pp"] = self.settings_pp
            log_dict["settings_heur"] = self.settings_heur
            log_dict["settings_tight"] = self.settings_tight
            log_dict["settings_domain"] = self.settings_domain
            log_dict["settings_mode"] = self.settings_mode
        wandb.log(log_dict)


    def run(self):
        if self.package == "FrankWolfe":
            self.jl.seval("isdir(\"benchmark_output\") || mkdir(\"benchmark_output\")")
            self.jl.seval(f"n = {self.build_args}[:n]")
            self.jl.seval(f"seed = {self.seed}")
            self.jl.seval(f"log_name = \"benchmark_output/{self.package}_{self.fw_variant}_{self.problem}_n$(n)_{self.seed}_{self.name}.txt\"")
            self.jl.seval(f"f = open(log_name, \"w\")")
            log_name = self.jl.log_name
            self.jl.seval(f"""redirect_stdout(f) do 
                global (bm, obj_counts, grad_counts, lmo_counts, dual_gaps, memory, times, trajectory) = benchmark_FW(
                        fw=\"{self.fw_variant}\",
                        problem=\"{self.problem}\",
                        build_args={self.build_args},
                        seed={self.seed},
                        fw_kwargs={self.kwargs},
                        num_runs={self.num_runs},
                        time_per_run={self.time_per_run},
                    )
                display(bm)
            end""")
            # bm, obj_counts, grad_counts, lmo_counts, dual_gaps, memory, times, trajectory = self.jl.bm, self.jl.obj_counts, self.jl.grad_counts, self.jl.lmo_counts, self.jl.dual_gaps, self.jl.memory, self.jl.times, self.jl.trajectory
            self.jl.seval("write(f, \"\n\")")
            self.jl.seval("close(f)")

            self.jl.seval(f"include(\"wandb_plot_utils.jl\")")
            self.jl.seval("labels = [\"iteration\", \"primal\", \"dual_bound\", \"dual_gap\", \"time\"]")
            self.jl.seval("""
                        trajectory_matrix = convert(Matrix{Real}, zeros(0, 5))
                        for i in trajectory
                            row = collect(i)
                            global trajectory_matrix = vcat(trajectory_matrix, row')
                        end
                        CSV.write(\"$(replace(log_name, \"txt\" => \"csv\"))\", DataFrame(trajectory_matrix, labels))
                        plot_data = extract_data(\"$(replace(log_name, \"txt\" => \"csv\"))\", dim=\"$n\", seed=\"$seed\")
                        plot_mat = zeros(0, 5)
                        for i in plot_data
                          row = collect(i)
                          global plot_mat = vcat(plot_mat, row')
                        end
                        steps = plot_mat[:, 1]
                        primal = plot_mat[:, 2]
                        dual_gap = plot_mat[:, 4]
                        time = plot_mat[:, 5]
                        """)
            steps, primal, dual_gap, time = self.jl.steps, self.jl.primal, self.jl.dual_gap, self.jl.time
            steps = [int(x) for x in steps]
            primal = [float(x) for x in primal]
            dual_gap = [float(x) for x in dual_gap]
            time = [float(x) for x in time]
            wandb.log({"Steps": steps, "Primal": primal, "Dual gap": dual_gap, "Time": time})

            
            
            # Create matplotlib 2x2 subplot
            fig, axes = plt.subplots(2, 2, figsize=(19.2, 10.8), dpi=100)
            fig.suptitle(f'Performance Metrics - {self.fw_variant}', fontsize=16)
            
            # Top-left: Primal vs Steps
            axes[0, 0].plot(steps, primal, 'b-', linewidth=4)
            # axes[0, 0].set_title('Primal Value vs Iterations')
            # axes[0, 0].set_xlabel('Iterations')
            axes[0, 0].set_ylabel('Primal Value')
            axes[0, 0].grid(True, alpha=0.3)
            
            # Top-right: Primal vs Time
            axes[0, 1].plot(time, primal, 'b-', linewidth=4)
            # axes[0, 1].set_title('Primal Value vs Time')
            # axes[0, 1].set_xlabel('Time (seconds)')
            # axes[0, 1].set_ylabel('Primal Value')
            axes[0, 1].grid(True, alpha=0.3)
            
            # Bottom-left: Dual Gap vs Steps
            axes[1, 0].plot(steps, dual_gap, 'r-', linewidth=4)
            # axes[1, 0].set_title('Dual Gap vs Iterations')
            axes[1, 0].set_xlabel('Iterations')
            axes[1, 0].set_ylabel('Dual Gap')
            axes[1, 0].grid(True, alpha=0.3)
            
            # Bottom-right: Dual Gap vs Time
            axes[1, 1].plot(time, dual_gap, 'r-', linewidth=4)
            # axes[1, 1].set_title('Dual Gap vs Time')
            axes[1, 1].set_xlabel('Time (seconds)')
            axes[1, 1].set_ylabel('Dual Gap')
            axes[1, 1].grid(True, alpha=0.3)
            
            plt.tight_layout()
            
            # Log the matplotlib figure to wandb
            wandb.log({
                "2x2 Performance Plot": wandb.Image(fig),
                "Primal plot iter": wandb.plot.line_series(
                    xs = [steps],
                    ys = [primal],
                    title="Primal value over iterations",
                    keys = [f"{self.fw_variant}"],
                    xname = "Iteration",
                ),
                "Primal plot time":
                wandb.plot.line_series(
                    xs = [time],
                    ys = [primal],
                    title="Primal value over time",
                    keys = [f"{self.fw_variant}"],
                    xname = "Time in seconds",
                ),
                "Dual gap plot iter": wandb.plot.line_series(
                    xs = [steps],
                    ys = [dual_gap],
                    title="Dual gap over iterations",
                    keys = [f"{self.fw_variant}"],
                    xname = "Iteration",
                ),
                "Dual gap plot time": wandb.plot.line_series(
                    xs = [time],
                    ys = [dual_gap],
                    title="Dual gap over time",
                    keys = [f"{self.fw_variant}"],
                    xname = "Time in seconds",
                )
            })
            
            # Close the figure to free memory
            plt.close(fig)
            
        elif self.package == "Boscia":
            self.jl.seval("isdir(\"benchmark_output\") || mkdir(\"benchmark_output\")")
            self.jl.seval(f"n = {self.build_args}[:n]")
            self.jl.seval(f"seed = {self.seed}")
            self.jl.seval(f"log_name = \"benchmark_output/{self.package}_{self.fw_variant}_{self.problem}_n$(n)_{self.seed}_{self.name}.txt\"")
            self.jl.seval(f"f = open(log_name, \"w\")")
            self.jl.seval(f"""redirect_stdout(f) do
                global (
                bm, 
                obj_counts, 
                grad_counts, 
                lmo_counts, 
                max_lb, 
                max_ub, 
                memory, 
                times, 
                solve_times, 
                lmo_calls, 
                lmo_per_layer, 
                active_set_sizes, 
                active_set_per_layer, 
                discarded_set_sizes, 
                discarded_set_per_layer,
                ) = benchmark_Boscia(
                        fw=\"{self.fw_variant}\",
                        problem=\"{self.problem}\",
                        build_args={self.build_args},
                        seed={self.seed},
                        boscia_kwargs={self.kwargs},
                        num_runs={self.num_runs},
                        time_per_run={self.time_per_run},
                        settings_bnb={self.settings_bnb},
                        settings_fw={self.settings_fw},
                        settings_tol={self.settings_tol},
                        settings_pp={self.settings_pp},
                        settings_heur={self.settings_heur},
                        settings_tight={self.settings_tight},
                        settings_domain={self.settings_domain},
                        settings_mode={self.settings_mode},
                    )
                    display(bm)
            end""")
            self.jl.seval("write(f, \"\n\")")
            self.jl.seval("close(f)")

            self.jl.seval(f"include(\"wandb_plot_utils.jl\")")
            self.jl.seval("labels = [\"iteration\",\"lower_bound\",\"upper_bound\",\"gap\",\"time\"]")
            self.jl.seval("""
                        trajectory_matrix = convert(Matrix{Real}, zeros(0, 5))
                        for i in 1:length(max_lb)
                            row = collect([Int(i), max_lb[i], max_ub[i], max_ub[i] - max_lb[i], solve_times[i]])
                            global trajectory_matrix = vcat(trajectory_matrix, row')
                        end
                        """)
            self.jl.seval("""
                        CSV.write(\"$(replace(log_name, \"txt\" => \"csv\"))\", DataFrame(trajectory_matrix, labels))
                        plot_data = extract_data(\"$(replace(log_name, \"txt\" => \"csv\"))\", dim=\"$n\", seed=\"$seed\")
                        plot_mat = zeros(0, 5)
                        """)
            self.jl.seval("""
                        for i in plot_data
                          row = collect(i)
                          global plot_mat = vcat(plot_mat, row')
                        end
                        """)
            self.jl.seval("""
                        steps = plot_mat[:, 1]
                        lower_bound = plot_mat[:, 2]
                        upper_bound = plot_mat[:, 3]
                        gap = plot_mat[:, 4]
                        time = plot_mat[:, 5]
                        """)
            steps, lower_bound, upper_bound, gap, time = self.jl.steps, self.jl.lower_bound, self.jl.upper_bound, self.jl.gap, self.jl.time
            lmo_calls, lmo_per_layer, active_set_sizes, active_set_per_layer, discarded_set_sizes, discarded_set_per_layer = self.jl.lmo_calls, self.jl.lmo_per_layer, self.jl.active_set_sizes, self.jl.active_set_per_layer, self.jl.discarded_set_sizes, self.jl.discarded_set_per_layer
            steps = [int(x) for x in steps]
            lower_bound = [float(x) for x in lower_bound]
            upper_bound = [float(x) for x in upper_bound]
            gap = [float(x) for x in gap]
            time = [float(x) for x in time]


            lmo_calls_per_layer = []
            for a in lmo_per_layer:
                lmo_calls_per_layer.append([int(x) for x in a])
            active_set_sizes_per_layer = []
            for a in active_set_per_layer:
                active_set_sizes_per_layer.append([int(x) for x in a])
            discarded_set_sizes_per_layer = []
            for a in discarded_set_per_layer:
                discarded_set_sizes_per_layer.append([int(x) for x in a])

            wandb.log({"LMO calls per layer": lmo_calls_per_layer})
            wandb.log({"Steps": steps, "Lower bound": lower_bound, "Upper bound": upper_bound, "Gap": gap, "Time": time})
            wandb.log({"LMO calls": lmo_calls})
            wandb.log({"Active set sizes": active_set_sizes})
            wandb.log({"Active set per layer": active_set_per_layer})
            wandb.log({"Discarded set sizes": discarded_set_sizes})
            wandb.log({"Discarded set per layer": discarded_set_per_layer})

            # create matplotlib plots
            fig, axes = plt.subplots(2, 2, figsize=(19.2, 10.8), dpi=100)
            fig.suptitle(f'Performance Metrics - {self.problem}', fontsize=16)

            # Top-left: Bounds vs Steps
            axes[0, 0].plot(steps, lower_bound, color=(0, 109/255, 219/255), linewidth=4, marker="o")
            axes[0, 0].plot(steps, upper_bound, color=(0.00, 0.49/255, 0.00), linewidth=4, marker="o")
            axes[0, 0].set_ylabel('Bounds')
            axes[0, 0].grid(True, alpha=0.3)

            # Top-right: Bounds vs Time
            axes[0, 1].plot(time, lower_bound, color=(0, 109/255, 219/255), linewidth=4, marker="o")
            axes[0, 1].plot(time, upper_bound, color=(0.00, 0.49/255, 0.00), linewidth=4, marker="o")
            # axes[0, 1].set_ylabel('Bounds')
            axes[0, 1].grid(True, alpha=0.3)

            # Bottom-left: Gap vs Steps
            axes[1, 0].plot(steps, gap, color=(182/255, 109/255, 255/255), linewidth=4, marker="o")
            axes[1, 0].set_xlabel('Iteration')
            axes[1, 0].set_ylabel('Gap')
            axes[1, 0].grid(True, alpha=0.3)

            # Bottom-right: Gap vs Time
            axes[1, 1].plot(time, gap, color=(182/255, 109/255, 255/255), linewidth=4, marker="o")
            axes[1, 1].set_xlabel('Time (seconds)')
            # axes[1, 1].set_ylabel('Gap')
            axes[1, 1].grid(True, alpha=0.3)

            plt.tight_layout()

            wandb.log({
                "2x2 Performance Plot": wandb.Image(fig),
                "Bound plot iter": wandb.plot.line_series(
                    xs = [steps, steps],
                    ys = [lower_bound, upper_bound],
                    title="Lower bound over iterations",
                    keys = [f"{self.fw_variant}_{self.problem}_{self.jl.n}_{self.name}_lower", f"{self.fw_variant}_{self.problem}_{self.jl.n}_{self.name}_upper"],
                    xname = "Iteration",
                ),
                "Bound plot time": wandb.plot.line_series(
                    xs = [time, time],
                    ys = [lower_bound, upper_bound],
                    title="Lower bound over time",
                    keys = [f"{self.fw_variant}_{self.problem}_{self.jl.n}_{self.name}_lower", f"{self.fw_variant}_{self.problem}_{self.jl.n}_{self.name}_upper"],
                    xname = "Time in seconds",
                ),
                "Gap plot iter": wandb.plot.line_series(

                    xs = [steps],
                    ys = [gap],
                    title="Gap over iterations",
                    keys = [f"{self.fw_variant}_{self.problem}_{self.jl.n}_{self.name}_gap"],
                    xname = "Iteration",
                ),
                "Gap plot time": wandb.plot.line_series(

                    xs = [time],
                    ys = [gap],
                    title="Gap over time",
                    keys = [f"{self.fw_variant}_{self.problem}_{self.jl.n}_{self.name}_gap"],
                    xname = "Time in seconds",
                )
            })

            plt.close(fig)

        else:
            raise ValueError(f"Invalid package to benchmark: {self.package}. Please choose from \'FrankWolfe\' or \'Boscia\'.")

        self.log_metrics()

