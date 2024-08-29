"""
Sets up benchmark for FrankWolfe, evaluates the run and returns the benchmark. 

# Arguments
- 'fw': Frank-Wolfe variant to use. Choose from:        "BPCG"
                                                        "Vanilla" 
                                                        "Away" 
                                                        "BCG"
                                                        "Lazy"
                                                        "PCG"
                                                        Frank-Wolfe function

- 'problem': LMO over which to optimize. Choose from:   "Simplex"
                                                        "Nuclear"
                                                        "Spectrahedron"
                                                        "Birkhoff"
                                                        "Sparse"
                                                        (f, grad!, lmo, x0) tuple for custom lmo and starting point
                                                            
- 'build_args::Vector{Tuple{Symbol, Any}}': Vector used to build args, e.g. [(:n, 100), (:rhs, 100_000)]
- 'seed': random seed used for StableRNG
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
                        fw="Vanilla", 
                        problem="Simplex",
                        build_args=[],
                        seed=1234, 
                        fw_kwargs=[],
                        seconds=3600,
                        evals=5,
                        samples=10000,
                        time_tolerance=0.05,
                        memory_tolerance=0.01,
                     )
    fw = @match fw begin
        "Vanilla"       => frank_wolfe
        "BCG"           => blended_conditional_gradient
        "BPCG"          => FrankWolfe.blended_pairwise_conditional_gradient
        "Away"          => away_frank_wolfe
        "PCG"           => FrankWolfe.pairwise_frank_wolfe
        "Lazy"          => lazified_conditional_gradient
        "DICG"          => FrankWolfe.decomposition_invariant_conditional_gradient
        _               => fw
    end

    # lmo 
    fw_args = @match problem begin
        "Simplex"       => build_simplex(; build_args..., seed=seed)
        "Birkhoff"      => build_birkhoff_fw(; build_args..., seed=seed)
        "Spectrahedron" => build_spectrahedron(; build_args...)
        "Sparse"        => build_sparse(; build_args...)
        "Nuclear"       => build_nuclear(; build_args...)
        _               => problem
    end

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
                                                        "Vanilla" 
                                                        "Away" 
                                                        "BCG"

    - 'problem': Problem setup which Boscia solves. Choose from:    "CubeSimpleInt"
                                                                    "CubeSimpleMix" 
                                                                    "Birkhoff" 
                                                                    "SparseReg"
                                                                    "Poisson"
                                                                    "Portfolio"
                                                                    "Lasso"
    - 'build_args': arguments for lmo and objective that can be passed by unpacking
    - 'seed': random seed used for StableRNG
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
                            problem="CubeSimpleInt",
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
        "BPCG"              => Boscia.BPCG()
        "Vanilla"           => Boscia.VanillaFrankWolfe()
        "Away"              => Boscia.AwayFrankWolfe()
        "BCG"               => Boscia.Blended()
        _                   => fw
    end

    # create args for 'Boscia.solve'
    boscia_args = @match problem begin
        "CubeSimpleInt"     => build_cube_simple_integer(; build_args..., seed=seed)
        "CubeSimpleMix"     => build_cube_simple_mixed(; build_args..., seed=seed)
        "Birkhoff"          => build_birkhoff_boscia(; build_args..., seed=seed)
        "SparseReg"         => build_sparse_reg(; build_args..., seed=seed)
        "Poisson"           => build_poisson_reg(; build_args..., seed=seed)
        "Portfolio"         => build_portfolio(; build_args..., seed=seed)
        "Lasso"             => build_lasso(; build_args..., seed=seed)
        _                   => problem
    end

    # Boscia args and kwargs
    boscia_kwargs   = convert(Vector{Tuple{Symbol, Any}}, boscia_kwargs)
    boscia_kwargs   = append!(boscia_kwargs, [(:variant, fw_algo)])

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

    f, grad!, lmo, x0 = args
    
    track_f = FrankWolfe.TrackingObjective(f);
    track_grad! = FrankWolfe.TrackingGradient(grad!)
    track_lmo = FrankWolfe.TrackingLMO(lmo)

    obj_counts      = Vector{Int64}([])
    lmo_counts      = Vector{Int64}([])
    grad_counts     = Vector{Int64}([])
    dual_gaps       = Vector{Float64}([])
    memory          = Vector{Float64}([])
    times           = Vector{Float64}([])

    for _ in 1:10
        track_lmo.counter = 0
        track_grad!.counter = 0
        track_f.counter = 0
        v = copy(x0)
        global evaluated = @benchmark begin 
            global _, _, _, dual_gap, _ = $func($track_f, $track_grad!, $track_lmo, $v; max_iteration=Inf, timeout=1_000, $kwargs...) 
        end samples=1 evals=1 seconds=3600 time_tolerance=time_tolerance memory_tolerance=memory_tolerance

        # Tracking is done once each for eval run and taken sample, so need to half
        push!(obj_counts, Int(track_f.counter / 2))
        push!(lmo_counts, Int(track_lmo.counter / 2))
        push!(grad_counts, Int(track_grad!.counter / 2))
        push!(dual_gaps, dual_gap)
        # save time in seconds
        push!(times, evaluated.times[1] / 1e9)
        if dual_gap < 1e-7
            # memory in GB, only if the run was successful (< 1000 seconds minutes)
            push!(memory, evalauted.memory / 1e9)
        end
    end

    params = evalauted.params
    params.samples = 10
    params.evals=1
    params.seconds=3600
    bm = BenchmarkTools.Trial(params, times, evaluated.gctimes, geom_shifted_mean(memory), evaluated.allocs)

    return bm
end;