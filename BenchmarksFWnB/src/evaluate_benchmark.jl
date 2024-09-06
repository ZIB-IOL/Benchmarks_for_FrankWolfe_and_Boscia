
"""
Sets up benchmark for FrankWolfe, evaluates the run and returns the benchmark. 

# Arguments
- 'fw': Frank-Wolfe variant to use. Choose from:        "BPCG"
                                                        "Vanilla" 
                                                        "Away" 
                                                        "BCG"
                                                        "Lazy"
                                                        "PCG"
                                                        "DICG"
                                                        "BDICG"
                                                        Frank-Wolfe function

- 'problem': LMO over which to optimize. Choose from:   "Simplex"
                                                        "Nuclear"
                                                        "Spectrahedron"
                                                        "Birkhoff"
                                                        "Sparse"
                                                        "A-Criterion"
                                                        "D-Criterion"
                                                        "Poisson"
                                                        (f, grad!, lmo, x0) tuple for custom lmo and starting point
                                                            
- 'build_args::Vector{Tuple{Symbol, Any}}': Vector used to build args, e.g. [(:n, 100), (:rhs, 100_000)]
- 'seed': random seed used for StableRNG
- 'fw_kwargs': keyword arguments for FrankWolfe algorithm, e.g. [(:epsilon, 1e-7), (:max_iteration, 20_000)]
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
        "BDICG"         => FrankWolfe.blended_decomposition_invariant_conditional_gradient
        _               => fw
    end

    # lmo 
    fw_args = @match problem begin
        "Simplex"       => build_simplex(; build_args...)
        "Birkhoff"      => build_birkhoff_fw(; build_args...)
        "Spectrahedron" => build_spectrahedron(; build_args...)
        "Sparse"        => build_sparse(; build_args...)
        "Nuclear"       => build_nuclear(; build_args...)
        "A-Criterion"   => build_a_opt(; build_args...)
        "D-Criterion"   => build_d_opt(; build_args...)
        "Poisson"       => build_poisson_fw(; build_args...)
        _               => problem
    end

    bm = run_benchmark( fw, 
                        fw_args, 
                        kwargs=fw_kwargs, 
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
                        time_tolerance=time_tolerance,
                        memory_tolerance=memory_tolerance,
                        )
    return bm
end;


"""
Runs the benchmark for a given function and args.

    # Arguments
    - 'func': function to benchmark
    - 'args': arguments for 'func'
    - 'kwargs': keyword arguments to be used in 'func'
    - 'time_tolerance': percent tolerance on measured time
    - 'memory_tolerance': percent tolerance on memory consumption

    # Returns
    - 'bm': evaluated benchmark run
    - 'obj_counts': vector with objective call counters
    - 'grad_counts': vector with gradient call counters
    - 'lmo_counts': vector with LMO call counters
    - 'dual_gaps': vector with FrankWolfe dual gaps 
    - 'memory': vector with memory in GB
    - 'times': vector with times in seconds
"""
function run_benchmark( func, 
                        args; 
                        kwargs=[], 
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
    memory          = Vector{Int64}([])
    times           = Vector{Float64}([])

    # needed for building trial
    gctimes         = Vector{Float64}([])
    allocs          = Vector{Int64}([])

    for _ in 1:3
        track_lmo.counter = 0
        track_grad!.counter = 0
        track_f.counter = 0
        v = copy(x0)
        global evaluated = @benchmark begin 
            global _, _, _, dual_gap, _ = $func($track_f, $track_grad!, $track_lmo, $v; max_iteration=Inf, timeout=900, epsilon=1e-7, $kwargs...) 
        end samples=1 evals=1 seconds=3600 time_tolerance=time_tolerance memory_tolerance=memory_tolerance

        # Tracking is done once each for eval run and taken sample, so need to half
        push!(obj_counts, Int(round(track_f.counter / 2)))
        push!(lmo_counts, Int(round(track_lmo.counter / 2)))
        push!(grad_counts, Int(round(track_grad!.counter / 2)))
        push!(dual_gaps, Float64(dual_gap))
        
        push!(times, Float64(evaluated.times[1])) 
        push!(gctimes, Float64(evaluated.gctimes[1]))

        push!(memory, evaluated.memory)
        push!(allocs, evaluated.allocs)
    end

    params = evaluated.params
    params.samples = 10
    params.evals=1
    params.seconds=3600
    mem_idx = findfirst(x -> x < 900, times ./ 1e9)

    bm = BenchmarkTools.Trial(params, times, gctimes, memory[mem_idx], maximum(allocs))

    return bm, obj_counts, grad_counts, lmo_counts, dual_gaps, memory ./ 1e9, times ./ 1e9
end;