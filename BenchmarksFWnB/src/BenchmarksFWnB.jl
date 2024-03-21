module BenchmarksFWnB

using BenchmarkTools

using Match

using FrankWolfe
using LinearAlgebra

using Boscia
using SCIP
import Bonobo
using Statistics

using MathOptInterface
const MOI = MathOptInterface

using Random

# FrankWolfe
include("FrankWolfe/SetupFrankWolfe.jl")

using .SetupFrankWolfe
const SetupFrankWolfe = BenchmarksFWnB.SetupFrankWolfe

const build_simplex = SetupFrankWolfe.build_simplex
const build_nuclear = SetupFrankWolfe.build_nuclear
const build_random = SetupFrankWolfe.build_random
const build_abs_sum = SetupFrankWolfe.build_abs_sum

export build_simplex, build_random, build_abs_sum, build_nuclear

# Boscia
include("Boscia/SetupBoscia.jl")

using .SetupBoscia
const SetupBoscia = BenchmarksFWnB.SetupBoscia

const build_birkhoff_boscia = SetupBoscia.build_birkhoff_boscia
const build_sparse_reg = SetupBoscia.build_sparse_reg
const build_cube_simple_integer = SetupBoscia.build_cube_simple_integer
const build_cube_simple_mixed = SetupBoscia.build_cube_simple_mixed

export build_birkhoff_boscia, build_sparse_reg

# Benchmark 
include("run_benchmark.jl")

const benchmark_FW = BenchmarksFWnB.benchmark_FW
const benchmark_Boscia = BenchmarksFWnB.benchmark_Boscia

export benchmark_FW, benchmark_Boscia
export run_benchmark, compare_benchmarks

end # module BenchmarksFWnB
