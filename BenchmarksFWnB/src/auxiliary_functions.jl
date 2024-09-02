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


"""
Saves the geometric mean 

# Arguments
- 'bm': evaluated benchmark run
- 'filepath': where to save the file
"""
function save_geomean(bm, filepath)
    # save geometric mean shifted by 1 second (1e9 ns)
    geomean_time = geom_shifted_mean(bm.times, shift=big"1e9")
    geomean_gc_time = geom_shifted_mean(bm.gctimes, shift=big"1e9")
    trial_estimate = BenchmarkTools.TrialEstimate(bm.params, geomean_time, geomean_gc_time, bm.memory, bm.allocs)
    BenchmarkTools.save(filepath, trial_estimate)
end


"""
Computes geometric mean of given sequence with shift.
"""
function geom_shifted_mean(xs; shift=big"0.0")
    n = length(xs)
    r = prod(xi + shift for xi in xs)
    return Float64(r^(1/n) - shift)
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
function read_setup_FW(; problem="Simplex")
    problems = ["Simplex", "Birkhoff", "Nuclear", "Sparse", "Spectrahedron"]
    if problem in problems
        try
            path = joinpath(@__DIR__, "FrankWolfe/setups_FW.jld2")
            setups = JLD2.load(path, problem)
            return setups
        catch 
            error("Invalid problem. No setup for $problem available.")
        end
    else
        error("Invalid problem, no setup for $problem available.")
    end
end


"""
For a given Frank-Wolfe 'problem', adds 'setup' to the vector containing all setups used in benchmark runs.
"""
function add_setup_FW(problem, setup)
    path = joinpath(@__DIR__, "FrankWolfe/setups_FW.jld2")
    setups_dict = load(path)
    append!(setups_dict[problem], [setup])
    save(path, setups_dict)
end

"""
For a given Boscia 'problem', adds 'setup' to the vector containing all setups used in benchmark runs.
"""
function add_setup_Boscia(problem, setup)
    path = joinpath(@__DIR__, "Boscia/setups_Boscia.jld2")
    setups_dict = load(path)
    append!(setups_dict[problem], [setup])
    save(path, setups_dict)
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

    else  
        # Boscia  
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
end;
