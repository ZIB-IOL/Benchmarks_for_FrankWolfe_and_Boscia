using JLD2

function run_active_set_quadratic(; branch="new")
    fw_variants = [ "Away",
                    "BCG",
                    "PCG",
                    "BPCG",
                  ]

    problems    = [ 
                    "Simplex",  
                    "Birkhoff", 
                    "Sparse", 
                    "Nuclear", 
                    "Spectrahedron" 
                  ] 

    seeds       = [ 6237259982982784263,
                  4029983743574629836,
                  8775360557774874450,
                  3837242124960531782,
                  2604058079039351027,
                ]
    
    # determine which branch to write to.
    working_dir = @__DIR__
    if branch === "master"
        display("You are about to write to the master branch directory. Are you sure you want to proceed? (y/n)")
        choice = readline()
        if choice in ["Y", "y"]
            branch_path = joinpath(working_dir, "../results/FrankWolfe/master/")
        else
            error("Killing the process.")
        end
    else
        branch_path = joinpath(working_dir, "../results/FrankWolfe/$branch/")
    end

    isdir(branch_path) || mkpath(branch_path)
    
    for problem in problems
        for variant in fw_variants
            @show variant, problem
            setups = load("src/FrankWolfe/setups_FW.jld2", problem)
            for setup_idx in eachindex(setups)
                # schedules one job per setup and seed
                for seed in seeds
                    run(`sbatch sbatch_active_set_quadratic.sh $variant $problem $setup_idx $seed $branch_path`)
                end
            end
        end
    end
end;
