objective = "Spectrahedron"
lmo = "Spectrahedron"

working_dir = @__DIR__
branch_path = joinpath(working_dir, "../results/FrankWolfe/master/")

isdir(branch_path) || mkpath(branch_path)

# PCG
variant = "PCG"
for i in 5:6
    run(`sbatch sbatch_frank_wolfe.sh $variant $objective $lmo $i $branch_path`)
end
