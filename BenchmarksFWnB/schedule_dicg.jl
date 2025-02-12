#import Pkg
using JLD2

function run_DICG_FW()
    fw_variants = [ "DICG", 
                    "BDICG",
                    ]

    problems    = [ "Simplex",
                    "Birkhoff",
                    "A-Criterion",  
                    "D-Criterion",
                    "Poisson", 	    
                    ]

    seeds       = [ 6237259982982784263,
                    4029983743574629836,
                    8775360557774874450,
                    3837242124960531782,
                    2604058079039351027,
                    ]    

    # define saving folder
    working_dir = @__DIR__
    branch_path = joinpath(working_dir, "../results/FrankWolfe/master/")

    isdir(branch_path) || mkpath(branch_path)

    # schedule jobs
    for problem in problems
        for variant in fw_variants
            @show variant, problem
            setups = load(joinpath(working_dir, "src/FrankWolfe/setups_FW.jld2"), problem)
            for setup_idx in eachindex(setups)
                for seed in seeds
                    # schedules one job per setup
                    run(`sbatch sbatch_frank_wolfe.sh $variant $problem $setup_idx $seed $branch_path`)
                end
            end
        end
    end
end;
