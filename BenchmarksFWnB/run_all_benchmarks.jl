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
<<<<<<< HEAD:BenchmarksFWnB/src/run_all_benchmarks.jl
    if branch === "main"
        display("You are about to write to the 'main' directory. Do you wish to continue? (y/n)")
        choice = readline()
        if choice in ["Y", "y"]
            branch_path = joinpath(working_dir, "../../results/Boscia/main/")
        else
            error("Killing process.")
        end
    else
        branch_path = joinpath(working_dir, "../../results/Boscia/$branch/")
        isdir(branch_path) || mkdir(branch_path)
=======
    if branch === "master"
        branch_path = joinpath(working_dir, "../results/master/Boscia/")
    elseif branch === "new" || branch === "new_branch"
        branch_path = joinpath(working_dir, "../results/new_branch/Boscia/")
    else
        display("Invalid choice of branch. Defaulting to 'new_branch'.")
        branch_path = joinpath(working_dir, "../results/new_branch/Boscia/")
>>>>>>> 88c65b70319af9bb09defd5ae577f4c981385347:BenchmarksFWnB/run_all_benchmarks.jl
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
<<<<<<< HEAD:BenchmarksFWnB/src/run_all_benchmarks.jl
        display("You are about to write to the master branch directory. Are you sure you want to proceed? (y/n)")
        choice = readline()
        if choice in ["Y", "y"]
            branch_path = joinpath(working_dir, "../../results/FrankWolfe/master/")
        else
            error("Killing the process.")
        end
    else
        branch_path = joinpath(working_dir, "../../results/FrankWolfe/$branch/")
        if isdir(branch_folder)
            branch_path = branch_folder
        else
            mkdir(branch_folder)
            branch_path = branch_folder
        end
=======
        branch_path = joinpath(working_dir, "../results/master/FrankWolfe/")
    elseif branch === "new" || branch === "new_branch"
        branch_path = joinpath(working_dir, "../results/new_branch/FrankWolfe/")
    else
        display("Invalid choice of branch. Defaulting to 'new_branch'.")
        branch_path = joinpath(working_dir, "../results/new_branch/FrankWolfe/")
>>>>>>> 88c65b70319af9bb09defd5ae577f4c981385347:BenchmarksFWnB/run_all_benchmarks.jl
    end
    
    for obj_lmo_idx in eachindex(objectives)
        objective   = objectives[obj_lmo_idx]
        lmo         = lmos[obj_lmo_idx]

        for variant in fw_variants
<<<<<<< HEAD:BenchmarksFWnB/src/run_all_benchmarks.jl
            try
                bm = benchmark_FW(; fw=variant, obj=objective, lmo=lmo, setup...)
                filename = variant * "_" * objective * "_" * lmo * "_"
            catch
                display("$variant on $objective objective and $lmo LMO failed while running the benchmark. No benchmark will be saved!")
                display("Proceeding with the next iteration.")
                continue
            end

            for mode in ["maximum", "mean", "median", "minimum"]
                filepath = joinpath(branch_path, filename * mode * ".json")
                save_benchmark(benchmark, mode=mode, filepath=filepath)
            end
=======
            @show variant, objective, lmo
            run(`sbatch sbatch_frank_wolfe_benchmark.sh $variant $objective $lmo $set_up_idx $branch_path`)
>>>>>>> 88c65b70319af9bb09defd5ae577f4c981385347:BenchmarksFWnB/run_all_benchmarks.jl
        end
    end
end
