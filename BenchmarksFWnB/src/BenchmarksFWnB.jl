module BenchmarksFWnB

using FrankWolfe
using Boscia
using MathOptInterface
using Random
const MOI = MathOptInterface

include("FrankWolfe/SetupFrankWolfe.jl")
include("FrankWolfe/create_data.jl")

using .SetupFrankWolfe

const create_data_FW = BenchmarksFWnB.create_data

export create_data_FW

end # module BenchmarksFWnB

using .BenchmarksFWnB