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
function run_benchmark(func, 
                       args; 
                       kwargs=[], 
                       seconds=3600, 
                       evals=5, 
                       samples=1000, 
                       time_tolerance=0.05, 
                       memory_tolerance=0.01,
                       )
    benchmarkable = @benchmarkable $func($args...; $kwargs...)
    evaluated = run(benchmarkable,
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
    - 'mode': determines what to compare. Choose from "median", "mean" or "minimum".
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
        "median" => (median(bm1), median(bm2))
        "mean" => (mean(bm1), mean(bm2))
        "minimum" => (minimum(bm1), minimum(bm2))
        _ => (median(bm1), median(bm2))
    end

    @show "Showing $mode comparison:\n"

    display(judge(comp_1, comp_2, time_tolerance=time_tolerance, memory_tolerance=memory_tolerance))
end;

"""
Saves median, mean or minimum of a benchmark to file.

# Arguments
- 'bm': evaluated benchmark run
- 'mode': "median", "mean" or "minimum"
- 'filepath': path relative to current directory where to save output. Has to be .json file
"""
function save_benchmark(bm; mode="median", filepath="median.json")

    @match mode begin
        "median" => BenchmarkTools.save("$filepath", median(bm))
        "mean" => BenchmarkTools.save("$filepath", mean(bm))
        "minimum" => BenchmarkTools.save("$filepath", minimum(bm))
        _ => BenchmarkTools.save("$filepath", median(bm))
    end
end

"""
Sets up benchmark for FrankWolfe, evaluates the run and returns the benchmark. 
If any one of 'lmo' or 'obj' is "nuclear", then both LMO and objective function are created for the nuclear setting.

    # Arguments
    - 'fw': Frank-Wolfe variant to use. Choose from:    "BPCG"
                                                        "vanilla" 
                                                        "away" 
                                                        "BCG"
                                                        "lazy"
                                                        "PCG"

    - 'lmo': LMO over which to optimize. Choose from:   "simplex"
                                                        "nuclear"
                                                        "spectrahedron"
                                                        "Birkhoff"
                                                        "sparse"
                                                        "TBD"

    - 'obj': objective function to optimize. Choose from:   "random MSE"
                                                            "abs_sum"
                                                            "nuclear"
                                                            "spectrahedron"
                                                            "TBD"
    - 'lmo_args': arguments for lmo that can be passed by unpacking
    - 'obj_args': arguments for objective that can be passed by unpacking
    - 'seed': random seed 
    - 'fw_kwargs': keyword arguments for FrankWolfe algorithm, e.g. [(:epsilon, 1e-7), (:max_iteration, 5000)]
    - 'seconds': time limit for benchmark run
    - 'evals': number of function evaluations per sample
    - 'samples': number of samples to take for benchmark
    - 'time_tolerance': percent tolerance for measured time
    - 'memory_tolerance': percent tolerance for measured memory usage

    # Returns 
    - 'bm': evaluated benchmark run
"""
function benchmark_FW(  ; 
                        fw="vanilla", 
                        lmo="simplex", 
                        obj="random MSE", 
                        lmo_args=[],
                        obj_args=[],
                        seed=1234, 
                        fw_kwargs=[],
                        seconds=3600,
                        evals=5,
                        samples=10000,
                        time_tolerance=0.05,
                        memory_tolerance=0.01,
                     )
    fw = @match fw begin
        "vanilla" => frank_wolfe
        "BCG" => blended_conditional_gradient
        "BPCG" => FrankWolfe.blended_pairwise_conditional_gradient
        "away" => away_frank_wolfe
        _ => frank_wolfe
    end

    # lmo 
    lmo, x0 = @match lmo begin
        "simplex" => build_simplex(lmo_args..., seed=seed)
        "Birkhoff" => build_birkhoff_lmo(lmo_args..., seed=seed)
        "spectrahedron" => build_spectrahedron_lmo(lmo_args..., seed=seed)
        "sparse" => build_sparse_lmo(lmo_args...)
        "nuclear" => build_nuclear_lmo(lmo_args...)
        _ => build_simplex(lmo_args..., seed=seed)
    end

    # objective
    f, grad! = @match obj begin 
        "random MSE" => build_random(obj_args..., seed=seed)
        "abs_sum" => build_abs_sum()
        "Birkhoff" => build_birkhoff_obj(obj_args..., seed=seed)
        "spectrahedron" => build_spectrahedron_obj(obj_args..., seed=seed)
        "nuclear" => build_nuclear_obj(obj_args..., seed=seed)
        _ => build_random(obj_args..., seed=seed)
    end

    fw_args = [f, grad!, lmo, x0]
    @suppress bm = run_benchmark( fw, 
                        fw_args, 
                        kwargs=fw_kwargs, 
                        seconds=seconds,
                        evals=evals,
                        samples=samples,
                        time_tolerance=time_tolerance,
                        memory_tolerance=memory_tolerance,
                        )
    return bm
end;

"""
Sets up benchmark for Boscia, evaluates the run and returns the benchmark.

    # Arguments
    - 'fw': Frank-Wolfe variant to use. Choose from:    "BPCG"
                                                        "vanilla" 
                                                        "away" 
                                                        "BCG"

    - 'problem': Problem setup which Boscia solves. Choose from:    "Cube Simple Int"
                                                                    "Cube Simple Mix" 
                                                                    "Birkhoff" 
                                                                    "Sparse reg"
    - 'build_args': arguments for lmo and objective that can be passed by unpacking
    - 'seed': random seed 
    - 'boscia_kwargs': keyword arguments for Boscia, e.g. [(:fw_epsilon, 1e-7), (:verbose, true)]
    - 'seconds': time limit for benchmark run
    - 'evals': number of function evaluations per sample
    - 'samples': number of samples to take for benchmark
    - 'time_tolerance': percent tolerance for measured time
    - 'memory_tolerance': percent tolerance for measured memory usage

    # Returns 
    - 'bm': evaluated benchmark run
"""
function benchmark_Boscia(  ; 
                            fw="BPCG", 
                            problem="Cube Simple Int",
                            build_args=[],
                            seed=1234,
                            boscia_kwargs=[],
                            seconds=3600,
                            evals=5,
                            samples=10000,
                            time_tolerance=0.05,
                            memory_tolerance=0.01,
                            )
    # FW variant to use
    fw_algo = @match fw begin
        "BPCG" => Boscia.BPCG()
        "vanilla" => Boscia.VanillaFrankWolfe()
        "away" => Boscia.AwayFrankWolfe()
        "BCG" => Boscia.Blended()
        _ => Boscia.BPCG()
    end

    # create args for 'Boscia.solve'
    args = @match problem begin
        "Cube Simple Int" => build_cube_simple_integer(build_args..., seed=seed)
        "Cube Simple Mix" => build_cube_simple_mixed(build_args..., seed=seed)
        "Birkhoff" => build_birkhoff_boscia(build_args..., seed=seed)
        "Sparse reg" => build_sparse_reg(build_args..., seed=seed)
        _ => build_cube_simple_integer(build_args..., seed=seed)
    end

    # Boscia args and kwargs
    boscia_args = [args...]
    boscia_kwargs = append!(boscia_kwargs, [(:variant, fw_algo)])

    # build and evaluate benchmark run
    @suppress bm = run_benchmark( Boscia.solve, 
                        boscia_args, 
                        kwargs=boscia_kwargs,
                        seconds=seconds,
                        evals=evals,
                        samples=samples,
                        time_tolerance=time_tolerance,
                        memory_tolerance=memory_tolerance,
                        )
    return bm
end;
