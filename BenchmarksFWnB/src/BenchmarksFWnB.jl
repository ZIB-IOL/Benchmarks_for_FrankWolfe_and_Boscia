module BenchmarksFWnB

using BenchmarkTools

using Match

using FrankWolfe

using Boscia
using SCIP
import Bonobo
using Statistics

using MathOptInterface
const MOI = MathOptInterface

using Random

# FrankWolfe
include("FrankWolfe/SetupFrankWolfe.jl")
# include("FrankWolfe/create_data.jl")

# Boscia
include("Boscia/SetupBoscia.jl")

# Benchmark 
include("run_benchmark.jl")

export run_benchmark, compare_benchmarks

using .SetupBoscia
using .SetupFrankWolfe

const SetupBoscia = BenchmarksFWnB.SetupBoscia
const SetupFrankWolfe = BenchmarksFWnB.SetupFrankWolfe

export SetupBoscia, SetupFrankWolfe

# FrankWolfe
const build_simplex = SetupFrankWolfe.build_simplex
const build_random = SetupFrankWolfe.build_random
const build_abs_sum = SetupFrankWolfe.build_abs_sum
const build_nuclear_lmo = SetupFrankWolfe.build_nuclear_lmo
const build_nuclear_obj = SetupFrankWolfe.build_nuclear_obj

export build_simplex, build_random, build_abs_sum
export build_nuclear_lmo, build_nuclear_obj

# Boscia
const build_birkhoff = SetupBoscia.build_data_birkhoff
const build_sparse_reg = SetupBoscia.build_data_sparse_reg

export build_birkhoff, build_sparse_reg

# const create_data_FW = BenchmarksFWnB.create_data_FW

# export create_data_FW

const benchmark_FW = BenchmarksFWnB.benchmark_FW

export benchmark_FW

end # module BenchmarksFWnB
