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
        "max"       => BenchmarkTools.save(filepath, maximum(bm))

        "median"    => BenchmarkTools.save(filepath, median(bm))
        "mean"      => BenchmarkTools.save(filepath, mean(bm))

        "minimum"   => BenchmarkTools.save(filepath, minimum(bm))
        "min"       => BenchmarkTools.save(filepath, minimum(bm))

        _           => BenchmarkTools.save(filepath, median(bm))
    end
end

# TODO: create function to compare benchmarks

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