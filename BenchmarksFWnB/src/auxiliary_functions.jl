"""
Builds and runs the benchmark for a given function and args.

    # Arguments
    - 'func': function to benchmark
    - 'args': arguments for 'func'
    - 'kwargs': keyword arguments to be used in 'func'
    - 'seconds': time limit for benchmark run
    - 'evals': number of evaluations per sample
    - 'samples: number of samples to take for benchmark
    - 'time_tolerance': percent tolerance on measured time
    - 'memory_tolerance': percent tolerance on memory consumption

    # Returns
    'evalauted': evaluated benchmark run
"""
function run_benchmark( func, 
                        args; 
                        kwargs=[], 
                        seconds=3600, 
                        evals=5, 
                        samples=1000, 
                        time_tolerance=0.05, 
                        memory_tolerance=0.01,
                        )
    benchmarkable   = @benchmarkable    $func($args...; $kwargs...)
    evaluated       = @suppress         run(benchmarkable,
                                            seconds=seconds,
                                            evals=evals,
                                            samples=samples,
                                            time_tolerance=time_tolerance,
                                            memory_tolerance=memory_tolerance,
                                            )
    return evaluated
end;


"""
Compares benchmark 1 (bm1) against benchmark 2 (bm2) and decides whether bm1 is an improvement over bm2.

    # Arguments
    - 'bm1': evaluated benchmark to compare
    - 'bm2': evaluated benchmark against which to compare
    - 'mode': determines what to compare. Choose from "median", "mean", "minimum" or "maximum".
    - 'time_tolerance': percent tolerance on measured time up to which comparison is neutral
    - 'memory_tolerance': percent tolerance on memory consumption up to which comparison is neutral

    # Prints
    - decision whether bm1 is better than bm2 w.r.t. time and memory (including percent improvement)
"""
function compare_benchmarks(bm1, 
                            bm2; 
                            mode="median",
                            time_tolerance=0.05, 
                            memory_tolerance=0.01
                            )
    comp_1, comp_2 = @match mode begin
        "median"    => (median(bm1), median(bm2))
        "mean"      => (mean(bm1), mean(bm2))
        "minimum"   => (minimum(bm1), minimum(bm2))
        "maximum"   => (maximum(bm1), maximum(bm2))
        _           => (bm1, bm2)
    end
    display(judge(comp_1, comp_2, time_tolerance=time_tolerance, memory_tolerance=memory_tolerance))
end;


"""
Saves median, mean or minimum of a benchmark to file.

# Arguments
- 'bm': evaluated benchmark run
- 'mode': "maximum", "median", "mean", "minimum"
- 'filepath': path relative to current directory where to save output. Has to be .json file
"""
function save_benchmark(bm; 
                        mode="median", 
                        filepath="median.json"
                        )
    @match mode begin
        "maximum"   => BenchmarkTools.save(filepath, maximum(bm))
        "median"    => BenchmarkTools.save(filepath, median(bm))
        "mean"      => BenchmarkTools.save(filepath, mean(bm))
        "minimum"   => BenchmarkTools.save(filepath, minimum(bm))
        _           => BenchmarkTools.save(filepath, median(bm))
    end
end

"""
Compares a Boscia benchmark 'bm' against previous values in all modes (mean, median, minimum, maximum)
and prints the comparison. 

# Arguments
- 'bm': computed benchmark. If 'nothing', the values of 'results/master' and 'results/new_branch' are compared
- 'fw': FW variant to compare against. If 'nothing', the function compares against all available runs
- 'problem': problem that was benchmarked. If 'nothing', compares against all problems (should only be done if whole branch was computed and saved)
"""
function compare_all_Boscia(; branch=nothing, fw=nothing, problem=nothing)
    working_dir = @__DIR__

    # master branch dir
    master_branch = joinpath(working_dir, "../../results/Boscia/main/")

    # new branch
    saved = false
    if benchmark === nothing
        # assumes benchmarks stored in 'results/new_branch'
        new_branch = joinpath(working_dir, "../../results/Boscia/new_branch/")
        branch = "new_branch"
        saved = true
    else
        new_branch = joinpath(working_dir, "../../results/Boscia/$branch/")
        saved = true
    end

    # compares stored values for master vs. new branch
    if saved
        for result_json in readdir(master_branch)
            try
                bm_master = BenchmarkTools.load(joinpath(master_branch, result_json))[1]
                bm_new = BenchmarkTools.load(joinpath(new_branch, result_json))[1]
                prms = bm_master.params
            catch err
                display("Failed to load benchmark.")
                display(err)
                display("Continuing with the next benchmark.")
                continue
            end
            display("$branch $result_json vs. Master $result_json")
            compare_benchmarks( bm_master, 
                                bm_new, 
                                mode=nothing,
                                time_tolerance=prms.time_tolerance, 
                                memory_tolerance=prms.memory_tolerance
                                )
        end
        return 
    end

    # benchmark was passed
    try
        problem ∈ ["CubeSimpleInt", "CubeSimpleMix", "Birkhoff", "SparseReg", "Poisson", "Portfolio", "Lasso"]
    catch
        error("Invalid problem to compare against.")
    end

    # compares against specific Frank-Wolfe variant of specific problem
    if fw !== nothing
        
        display("Freshly computed vs. Master")
        display("Problem: $problem")
        display("Frank-Wolfe variant: $fw")
        println()
        for mode in ["maximum", "mean", "median", "minimum"]
            problem_file = problem * "_" * fw * "_" * mode * ".json"
            result_json = joinpath(master_branch, problem_file)
            bm_master = BenchmarkTools.load(result_json)[1]
            cmp = @match mode begin
                "median"    => median(benchmark)
                "mean"      => mean(benchmark)
                "minimum"   => minimum(benchmark)
                "maximum"   => maximum(benchmark)
                _           => error("Invalid mode!")
            end
            display("$mode comparison")
            compare_benchmarks( cmp,
                                bm_master,
                                mode=nothing,
                                time_tolerance=benchmark.params.time_tolerance,
                                memory_tolerance=benchmark.params.memory_tolerance
                                )
        end
        return
    end
    # compare against all Frank-Wolfe variants for given problem
    display("Freshly computed vs. Master: $problem")
    for result_json in readdir(master_branch)
        if startswith(result_json, problem)
            bm_master = BenchmarkTools.load(joinpath(master_branch, result_json))[1]
            name    = split(split(result_json, '.')[1], '_')
            mode    = name[end]
            variant = name[2]
            cmp = @match mode begin
                "median"    => median(benchmark)
                "mean"      => mean(benchmark)
                "minimum"   => minimum(benchmark)
                "maximum"   => maximum(benchmark)
                _           => error("Invalid filename!")
            end
            display("$mode comparison for $variant")
            compare_benchmarks( cmp, 
                                bm_master, 
                                mode=nothing,
                                time_tolerance=benchmark.params.time_tolerance, 
                                memory_tolerance=benchmark.params.memory_tolerance
                                )
        end
    end
    return
end

"""
Compares a FrankWolfe benchmark 'bm' against previous values in all modes (mean, median, minimum, maximum)
and prints the comparison.

# Arguments
- 'branch': name of the branch folder to compare against. Alternatively, an evaluated benchmark run can be passed to compare against saved values.
- 'fw': FW variant to compare against. If 'nothing', the function compares against all available runs
- 'obj': objective that was benchmarked
- 'lmo': LMO that was benchmarked
"""
function compare_all_FW(; branch=nothing, fw=nothing, obj="MSE", lmo="Simplex")
    working_dir = @__DIR__

    # master branch dir
    master_branch = joinpath(working_dir, "../../results/FrankWolfe/master/")

    # new branch
    stored = false
    if branch === nothing
        # assumes benchmarks stored in 'results/new_branch'
        new_branch = joinpath(working_dir, "../../results/FrankWolfe/new_branch/")
        saved = true
    else
        new_branch = joinpath(working_dir, "../../results/FrankWolfe/$branch/")
        saved = true
    end

    # compares stored values for master vs. new branch
    if saved
        for result_json in readdir(master_branch)
            try
                bm_master = BenchmarkTools.load(joinpath(master_branch, result_json))[1]
                bm_new = BenchmarkTools.load(joinpath(new_branch, result_json))[1]
                prms = bm_master.params
            catch
                continue
            end
            display("New branch $result_json vs. Master $result_json")
            compare_benchmarks( bm_master, 
                                bm_new, 
                                mode=nothing,
                                time_tolerance=prms.time_tolerance, 
                                memory_tolerance=prms.memory_tolerance
                                )
        end
        return 
    end

    # evaluated benchmark was passed
    try
        obj ∈ ["MSE", "Nuclear", "Spectrahedron", "Birkhoff", "Sparse"]
        lmo ∈ ["Simplex", "Nuclear", "Spectrahedron", "Birkhoff", "Sparse"]
    catch
        error("Invalid problem to compare against.")
    end

    # compares against specific Frank-Wolfe variant of specific problem
    if fw !== nothing
        display("Freshly computed vs. Master")
        display("objective: $obj")
        display("LMO: $lmo")
        display("Frank-Wolfe variant: $fw")
        println()
        for mode in ["maximum", "mean", "median", "minimum"]
            problem_file = fw * "_" * obj * "_" * lmo * "_" * mode * ".json"
            result_json = joinpath(master_branch, problem_file)
            bm_master = BenchmarkTools.load(result_json)[1]
            cmp = @match mode begin
                "median"    => median(benchmark)
                "mean"      => mean(benchmark)
                "minimum"   => minimum(benchmark)
                "maximum"   => maximum(benchmark)
                _           => error("Invalid mode!")
            end
            display("$mode comparison")
            compare_benchmarks( cmp,
                                bm_master,
                                mode=nothing,
                                time_tolerance=benchmark.params.time_tolerance,
                                memory_tolerance=benchmark.params.memory_tolerance
                                )
        end
        return
    end

    # compare against all Frank-Wolfe variants for given problem
    display("Branch vs. Master")
    display("Objective: $obj")
    display("LMO: $lmo")
    for result_json in readdir(master_branch)
        if contains(result_json, obj) && contains(result_json, lmo)
            bm_master = BenchmarkTools.load(joinpath(master_branch, result_json))[1]
            name    = split(split(result_json, '.')[1], '_')
            mode    = name[end]
            variant = name[1]
            cmp = @match mode begin
                "median"    => median(benchmark)
                "mean"      => mean(benchmark)
                "minimum"   => minimum(benchmark)
                "maximum"   => maximum(benchmark)
                _           => error("Invalid filename!")
            end
            display("$mode comparison for $variant")
            compare_benchmarks( cmp, 
                                bm_master, 
                                mode=nothing,
                                time_tolerance=benchmark.params.time_tolerance, 
                                memory_tolerance=benchmark.params.memory_tolerance
                                )
        end
    end
    return
end


"""
Given a Bosica problem, reads out and returns a vector of setups for this problem.
"""
function read_setup_Boscia(; problem="CubeSimpleInt")
    problems = ["CubeSimpleInt", "CubeSimpleMix", "Birkhoff", "SparseReg", "Portfolio", "Poisson", "Lasso"]
    if problem in problems
        path = joinpath(@__DIR__, "Boscia/setups_Boscia.jld2")
        setups = JLD2.load(path, problem)
        return setups
    else
        error("Invalid problem, no setup for $problem available.")
    end
end


"""
Given an objective and LMO pair, reads out and returns a vector of setups for this problem.
"""
function read_setup_FW(; objective="MSE", lmo="Simplex")
    objectives = ["MSE", "Birkhoff", "Nuclear", "Sparse", "Spectrahedron"]
    lmos = ["Simplex", "Birkhoff", "Nuclear", "Sparse", "Spectrahedron"]
    if objective in objectives
        if lmo in lmos
            try
                path = joinpath(@__DIR__, "FrankWolfe/setups_FW.jld2")
                setups = JLD2.load(path, objective * "_" * lmo)
                return setups
            catch 
                error("Invalid objective + LMO combination. No setup for $objective $lmo available.")
            end
        else
            error("Invalid LMO, no setup for $lmo available.")
        end
    else
        error("Invalid objective, no setup $objective available.")
    end
end


"""
For a given 'problem', adds 'setup' to the vector containing all setups used in benchmark runs.
"""
function add_setup(problem, setup)
    if contains(problem, '_')
        # FrankWolfe
        path = joinpath(@__DIR__, "FrankWolfe/setups_FW.jld2")
        setups_dict = load(path)
        append!(setups_dict[problem], [setup])
        save(path, setups_dict)
    else
        # Boscia
        path = joinpath(@__DIR__, "Boscia/setups_Boscia.jld2")
        setups_dict = load(path)
        append!(setups_dict[problem], [setup])
        save(path, setups_dict)
    end
end


"""
Resets the setup vector for a given problem. If "all" is passed for problem, resets all problem setups.
"""
function reset_setups(; package="FrankWolfe", problem="MSE_Simplex")
    if package === "FrankWolfe"
        setups_path = joinpath(@__DIR__, "FrankWolfe/setups_FW.jld2")
        setups = load(setups_path)
        if problem === "all"
            for (key, _) in setups
                setups[key] = []
            end
            save(setups_path, setups)
        else
            try
                global setups[problem] = []
            catch e
                println("Invalid problem was given.")
                rethrow(e)
            end
            save(setups_path, setups)
        end
    else  # Boscia  
        setups_path = joinpath(@__DIR__, "Boscia/setups_Boscia.jld2")
        setups = load(setups_path)
        if problem === "all"
            for (key, _) in setups
                setups[key] = []
            end
            save(setups_path, setups)
        else
            try
                global setups[problem] = []
            catch e
                println("Invalid problem was given.")
                rethrow(e)
            end
            save(setups_path, setups)
        end
    end
end