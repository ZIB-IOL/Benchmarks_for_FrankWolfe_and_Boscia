module SetupFrankWolfe

using Random
using FrankWolfe
using BenchmarkTools

working_dir = @__DIR__

for dir in readdir(working_dir)
    if !endswith(dir, ".jl")
        for file in readdir(joinpath(working_dir, dir))
            include(joinpath(working_dir, dir, file))
        end
    end
end

end;  # module