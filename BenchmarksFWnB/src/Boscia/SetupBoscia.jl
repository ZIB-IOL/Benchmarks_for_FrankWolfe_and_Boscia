module SetupBoscia

using Boscia
using Random
using BenchmarkTools

working_dir = @__DIR__

for file in readdir(working_dir)
    if endswith(file, ".jl") && file !== "SetupBoscia.jl"
        include(joinpath(working_dir, file))
    end
end

export build_data_birkhoff, build_data_sparse_reg

end;
