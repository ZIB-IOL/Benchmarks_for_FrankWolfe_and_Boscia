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

    # setup for each problem. To change Boscia kwargs use '(:boscia_kwargs, [(:kwarg1, val), ...])'
    problem_setups  = [ [(:build_args, [(:n, 20)]), (:seconds, 3600), (:evals, 5), (:samples, 10000), (:seed, 1234)], 
                        [(:build_args, [(:n, 20)]), (:seconds, 3600), (:evals, 5), (:samples, 10000), (:seed, 1234)], 
                        [(:build_args, [(:n, 10), (:k, 5)]), (:seconds, 3600), (:evals, 5), (:samples, 10000), (:seed, 1234)], 
                        [(:build_args, [(:n, 20)]), (:seconds, 3600), (:evals, 5), (:samples, 10000), (:seed, 1234)], 
                        [(:build_args, [(:n, 20), (:p, 20), (:k, 10)]), (:seconds, 3600), (:evals, 5), (:samples, 10000), (:seed, 1234)], 
                        [(:build_args, [(:n, 30)]), (:seconds, 3600), (:evals, 5), (:samples, 10000), (:seed, 1234)], 
                        [(:build_args, [(:n, 20), (:M_g, 5.0), (:lambda_0_g, 0.0), (:lambda_2_g, 0.0)]), (:seconds, 3600), (:evals, 5), (:samples, 10000), (:seed, 1234)],
                      ]

    # determine which branch to save the output to. Only writes to 'master' if explicitly passed as such
    working_dir = @__DIR__
    if branch === "master"
        branch_path = joinpath(working_dir, "../results/master/Boscia/")
    elseif branch === "new" || branch === "new_branch"
        branch_path = joinpath(working_dir, "../results/new_branch/Boscia/")
    else
        display("Invalid choice of branch. Defaulting to 'new_branch'.")
        branch_path = joinpath(working_dir, "../results/new_branch/Boscia/")
    end

    # run each problem + FW variant combination
    for problem_idx in eachindex(problems)
        problem = problems[problem_idx]
        setup = problem_setups[problem_idx]

        for variant in fw_variants
            # continue in case benchmark errors
            @show problem_idx, variant, set_up_idx
            run(`sbatch sbatch_boscia_benchmark.sh $problem_idx $variant $set_up_idx $branch_path`)
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

    objectives  = [ "MSE",
                    "Birkhoff",
                    "Nuclear",
                    "Sparse",
                    "Spectrahedron",
                  ]

    lmos        = [ "Simplex",
                    "Birkhoff",
                    "Nuclear",
                    "Sparse",
                    "Spectrahedron",
                  ] 
    
    # setup for each obj + LMO combination. To add FW kwargs use '(:fw_kwargs, [(:kwarg1, val), ...])'
    setups      = [ [(:obj_args, [(:n, 1000), (:k, 300)]), (:lmo_args, [(:n, 300)]), (:seconds, 3600), (:evals, 5), (:samples, 10000), (:seed, 1234)],
                    [(:obj_args, [(:n, 100)]), (:lmo_args, [(:n, 100)]), (:seconds, 3600), (:evals, 5), (:samples, 10000), (:seed, 1234)],
                    [(:obj_args, [(:n, 500), (:k, 30)]), (:lmo_args, [(:dim, 500)]), (:seconds, 3600), (:evals, 5), (:samples, 10000), (:seed, 1234)],
                    [(:obj_args, [(:n, 100)]), (:lmo_args, [(:K, 40), (:dim, 100), (:rhs, 1.0)]), (:seconds, 3600), (:evals, 5), (:samples, 10000), (:seed, 1234)],
                    [(:obj_args, [(:entries, 1000), (:range, 1500)]), (:lmo_args, [(:n, 1500), (:radius, 1.0)]), (:seconds, 3600), (:evals, 5), (:samples, 10000), (:seed, 1234)],
                  ]

    # determine which branch to write to.
    working_dir = @__DIR__
    if branch === "master"
        branch_path = joinpath(working_dir, "../results/master/FrankWolfe/")
    elseif branch === "new" || branch === "new_branch"
        branch_path = joinpath(working_dir, "../results/new_branch/FrankWolfe/")
    else
        display("Invalid choice of branch. Defaulting to 'new_branch'.")
        branch_path = joinpath(working_dir, "../results/new_branch/FrankWolfe/")
    end
    
    for obj_lmo_idx in eachindex(objectives)
        objective   = objectives[obj_lmo_idx]
        lmo         = lmos[obj_lmo_idx]

        for variant in fw_variants
            @show variant, objective, lmo
            run(`sbatch sbatch_frank_wolfe_benchmark.sh $variant $objective $lmo $set_up_idx $branch_path`)
        end
    end
end
