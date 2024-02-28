module SetupFrankWolfe

using Random 
using LinearAlgebra
using FrankWolfe

const algs = ["vanilla", "away", "blended", "blended_pairwise"]
const lmos = ["ProbSimplex", "LpNorm", "Birkhoff"]

working_dir = @__DIR__

for dir in readdir(working_dir)
    if !endswith(dir, ".jl")
        file = readdir(joinpath(working_dir, dir))[1]
        include(joinpath(working_dir, dir, file))
    end
end

end  # module