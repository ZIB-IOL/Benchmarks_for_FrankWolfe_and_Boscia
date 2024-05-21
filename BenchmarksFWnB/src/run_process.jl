"""
For a FW benchmark, ARGS should contain the 5 arguments:
    'branch', 
    'FW variant',
    'objective',
    'LMO',
    'setup index'

For a Boscia benchmark, ARGS should contain the 4 arguments:
    'branch',
    'FW variant',
    'problem',
    'setup index'
"""

using BenchmarksFWnB

if length(ARGS) == 4
    # Boscia
    branch, fw_variant, problem, setup_idx = ARGS

    if branch === "main"
        println("You are about to write to 'main'. Are you sure you want to continue? (y/n)")
        choice = readline()
        if choice ∉ ["Y", "y"]
            error("Killing process.")
        end
        println("Continuing run")
    end
    setup = read_setup_Boscia(problem=problem)[parse(Int64, setup_idx)]
    try
        global bm = benchmark_Boscia(; fw=fw_variant, problem=problem, setup...)
        global filename = problem * "_" * fw_variant * "_" * setup_idx * "_"
    catch err
        println("Run of $problem with $fw_variant failed. Process killed.")
        rethrow(err)
    end
    
    # saving benchmark
    branch_path = joinpath(@__DIR__, "../../results/Boscia/$branch/")
    isdir(branch_path) || mkdir(branch_path)
    println("Benchmark run successful")
    println("Displaying results for $problem solved with $fw_variant Frank-Wolfe, setup $setup_idx")
    display(bm)
    println()
    println("Saving results...")
    for mode in ["maximum", "mean", "median", "minimum"]
        try
            save_benchmark(bm; mode=mode, filepath=joinpath(branch_path, filename * mode * ".json"))
        catch err
            println("Saving data failed.")
            rethrow(err)
        end
    end
    println("Saving successful. Results are saved at $branch_path.")

elseif length(ARGS) == 5
    # Frank-Wolfe
    branch, fw_variant, objective, lmo, setup_idx = ARGS

    if branch === "master"
        println("You are about to write to 'master'. Are you sure you wish to continue? (y/n)")
        choice = readline()
        if choice ∉ ["Y", "y"]
            error("Killing process.")
        end
        println("Continuing run.")
    end
    problem = objective * "_" * lmo
    setup = read_setup_FW(objective=objective, lmo=lmo)[parse(Int64, setup_idx)]
    try
        global bm = benchmark_FW(; fw=fw_variant, obj=objective, lmo=lmo, setup...)
        global filename = fw_variant * "_" * problem * "_" * setup_idx * "_"
    catch err 
        println("Run of $fw_variant on $lmo LMO with $objective objective failed. Process killed.")
        rethrow(err)
    end

    # saving benchmark
    branch_path = joinpath(@__DIR__, "../../results/FrankWolfe/$branch/")
    isdir(branch_path) || mkdir(branch_path)
    println("Benchmark run successful")
    println("Displaying results for $fw_variant Frank-Wolfe on $lmo LMO with $objective objective, setup $setup_idx")
    display(bm)
    println()
    println("Saving results...")
    for mode in ["maximum", "mean", "median", "minimum"]
        try
            save_benchmark(bm; mode=mode, filepath=joinpath(branch_path, filename * mode * ".json"))
        catch err
            println("Saving data failed.")
            rethrow(err)
        end
    end
    println("Saving successful. Results are saved at $branch_path.")

else
    println("Incorrect number of arguments provided. Please make sure that you only pass the expected arguments.")
    println("Exiting process.")
end
