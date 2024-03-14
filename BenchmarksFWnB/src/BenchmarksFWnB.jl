module BenchmarksFWnB

using BenchmarkTools
using FrankWolfe
using Boscia
using MathOptInterface
using Random
const MOI = MathOptInterface
using Random # -> Switch to StableRNG!!
using SCIP
using LinearAlgebra
import HiGHS
using Statistics
using Match

include("FrankWolfe/SetupFrankWolfe.jl")
include("FrankWolfe/create_data.jl")

using .SetupFrankWolfe

const create_data_FW = BenchmarksFWnB.create_data

export create_data_FW

end # module BenchmarksFWnB
