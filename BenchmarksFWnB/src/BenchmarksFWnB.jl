module BenchmarksFWnB

using BenchmarkTools

# Math
using LinearAlgebra
using MathOptInterface
const MOI = MathOptInterface
using Statistics
using Distributions

# RNG 
using StableRNGs
using Random

# FrankWolfe
using FrankWolfe
using SparseArrays

# Boscia
using Boscia
using SCIP
import HiGHS

# misc.
using Match
using Suppressor
using JLD2

# FrankWolfe
working_dir = @__DIR__
working_dir = joinpath(working_dir, "FrankWolfe/")
for dir in readdir(working_dir)
    if !contains(dir, ".jl")
        for file in readdir(joinpath(working_dir, dir))
            include(joinpath(working_dir, dir, file))
        end
    end
end

# Boscia
working_dir = @__DIR__
working_dir = joinpath(working_dir, "Boscia/")

for file in readdir(working_dir)
    if endswith(file, ".jl")
        include(joinpath(working_dir, file))
    end
end

# Benchmark 
include("evaluate_benchmark.jl")
include("auxiliary_functions.jl")

export benchmark_FW, benchmark_Boscia

export run_benchmark, compare_benchmarks, save_benchmark, save_geomean
export read_setup_Boscia, read_setup_FW, add_setup_FW, add_setup_Boscia, reset_setups

end # module BenchmarksFWnB

