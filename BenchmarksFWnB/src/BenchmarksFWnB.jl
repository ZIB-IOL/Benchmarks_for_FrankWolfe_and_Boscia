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
using SCIP
import HiGHS

# misc.
using Match
using Suppressor

# FrankWolfe
working_dir = @__DIR__
working_dir = joinpath(working_dir, "FrankWolfe/")
for dir in readdir(working_dir)
    if !endswith(dir, ".jl")
        for file in readdir(joinpath(working_dir, dir))
            include(joinpath(working_dir, dir, file))
        end
    end
end

export build_spectrahedron_lmo, build_spectrahedron_obj
export build_birkhoff_lmo, build_birkhoff_obj   
export build_simplex, build_random
export build_nuclear_lmo, build_nuclear_obj
export build_sparse_lmo, build_sparse_obj

# Boscia
working_dir = @__DIR__
working_dir = joinpath(working_dir, "Boscia/")

for file in readdir(working_dir)
    include(joinpath(working_dir, file))
end

export build_birkhoff_boscia, build_sparse_reg, build_cube_simple_integer, build_cube_simple_mixed
export build_lasso, build_poisson_reg, build_portfolio, build_sparse_reg

# Benchmark 
include("evaluate_benchmark.jl")
include("auxiliary_functions.jl")
include("run_all_benchmarks.jl")

export benchmark_FW, benchmark_Boscia
export run_benchmark, compare_benchmarks, save_benchmark, compare_all_Boscia, compare_all_FW
export run_all_Boscia, run_all_FW

end # module BenchmarksFWnB

