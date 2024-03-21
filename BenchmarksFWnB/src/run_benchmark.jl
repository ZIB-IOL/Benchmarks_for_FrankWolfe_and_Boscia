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
    benchmarkable = @benchmarkable $func($args..., $kwargs...)
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
    - 'time_tolerance': percent tolerance on measured time up to which comparison is neutral
    - 'memory_tolerance': percent tolerance on memory consumption up to which comparison is neutral

    # Prints
    - decision whether bm1 is better than bm2 w.r.t. time and memory (including percent improvement)
"""
function compare_benchmarks(bm1, 
                            bm2; 
                            time_tolerance=0.05, 
                            memory_tolerance=0.01
                            )
    median1 = median(bm1)
    median2 = median(bm2)
    println("MEDIAN COMPARISON: \n")
    display(judge(median1, median2, time_tolerance=time_tolerance, memory_tolerance=memory_tolerance))
end;

"""
Sets up benchmark for FrankWolfe, evaluates the run and returns the benchmark. 
If any one of 'lmo' or 'obj' is "nuclear", then both LMO and objective function are created for the nuclear setting.

    # Arguments
    - 'fw': Frank-Wolfe variant to use. Choose from:    "BPCG"
                                                        "vanilla" 
                                                        "away" 
                                                        "BCG"

    - 'lmo': LMO over which to optimize. Choose from:   "simplex"
                                                        "nuclear"
                                                        "spectrahedron"
                                                        "Birkhoff"
                                                        "sparse"
                                                        "TBD"

    - 'obj': objective function to optimize. Choose from:   "random MSE"
                                                            "abs_sum"
                                                            "nuclear"
                                                            "TBD"
    - 'n': value of 'n', where applicable
    - 'k': value of 'k', where applicable
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
                        n=10,
                        k=5, 
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
    if lmo == "nuclear" || obj == "nuclear"
        f, grad!, lmo, x0 = build_nuclear(n=n, k=k, seed=seed)
    else
        lmo, x0 = @match lmo begin
            "simplex" => build_simplex(dim=dim, seed=seed)
            "Birkhoff" => build_birkhoff_FW
            _ => build_simplex(dim=dim, seed=seed)
        end
        f, grad! = @match obj begin 
            "random MSE" => build_random(dim=dim, seed=seed)
            "abs sum" => build_abs_sum()
            _ => build_random(dim=dim, seed=seed)
        end
    end

    fw_args = [f, grad!, lmo, x0]
    bm = run_benchmark( fw, 
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
    - 'n': value of 'n', where applicable.
    - 'k': value of 'k', where applicable.
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
                            n=10, 
                            k=5, 
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
        "Cube Simple Int" => build_cube_simple_integer(n=n, seed=seed)
        "Cube Simple Mix" => build_cube_simple_mixed(n=n, seed=seed)
        "Birkhoff" => build_birkhoff_boscia(n=n, k=k, seed=seed)
        "Sparse reg" => build_sparse_reg(n0=n, seed=seed)
        _ => build_cube_simple()
    end

    # Boscia args and kwargs
    boscia_args = [args...]
    boscia_kwargs = append!(boscia_kwargs, [(:variant, fw_algo)])

    # build and evaluate benchmark run
    bm = run_benchmark( Boscia.solve, 
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
