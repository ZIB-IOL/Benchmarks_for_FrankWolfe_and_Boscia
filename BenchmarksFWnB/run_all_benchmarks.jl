using JLD2
using Pkg

"""
Runs each Boscia problem with each available FW variant and saves the result to the desired directory.
"""
function run_all_Boscia(; branch="new")
    fw_variants     = [ "BPCG", 
                        "Vanilla", 
                        "Away", 
                        "BCG",
                      ]
    
    problems        = [ "CubeSimpleInt", 
                        "CubeSimpleMix", 
                        "Birkhoff", 
                        "SparseReg", 
                        "Poisson", 
                        "Portfolio", 
                        "Lasso"
                      ]

    # update package version to branch
    try 
        Pkg.add(url="https://github.com/ZIB-IOL/Boscia.jl", rev=branch)
    catch e
        rethrow(e)
    end

    # determine which branch to save the output to. Only writes to 'main' if explicitly passed as such
    working_dir = @__DIR__
    if branch === "main"
        display("You are about to write to the 'main' directory. Do you wish to continue? (y/n)")
        choice = readline()
        if choice in ["Y", "y"]
            branch_path = joinpath(working_dir, "../results/Boscia/main/")
        else
            error("Killing process.")
        end
    else
        branch_path = joinpath(working_dir, "../results/Boscia/$branch/")
    end

    isdir(branch_path) || mkpath(branch_path)

    # run each problem + FW variant combination
    for problem_idx in eachindex(problems)
        problem = problems[problem_idx]
        for variant in fw_variants
            @show problem, variant
            setups = load("src/Boscia/setups_Boscia.jld2", problem)
            for setup_idx in eachindex(setups)
                # schedules one job per setup
                run(`sbatch sbatch_boscia.sh $problem $variant $setup_idx $branch_path`)
            end
        end
    end
end


"""
Runs each Frank-Wolfe variant on the pairs (objectives[i], lmos[i]) and saves the result to the desired branch. 
"""
function run_all_FW(; branch="new")
    fw_variants = [ "Vanilla",
                    "Away",
                    "Lazy",
                    "BCG",
                    "PCG",
                    "BPCG",
                  ]

    problems    = [ "Simplex",
                    "Birkhoff",
                    "Nuclear",
                    "Sparse",
                    "Spectrahedron",
                    "A-Criterion",
                    "D-Criterion",
                    "Poisson",
                  ] 

    update package version to branch version
    try 
        Pkg.add(url="https://github.com/ZIB-IOL/FrankWolfe.jl", rev=branch)
    catch e
        rethrow(e)
    end
    
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
                # schedules one job per setup
                run(`sbatch sbatch_frank_wolfe.sh $variant $problem $setup_idx $branch_path`)
            end
        end
    end
end
