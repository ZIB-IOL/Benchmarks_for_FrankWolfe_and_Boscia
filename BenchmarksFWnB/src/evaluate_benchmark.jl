
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
                        num_runs=3,
                        time_per_run=60,
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
        "Simplex"       => build_simplex(; seed=seed, build_args...)
        "Birkhoff"      => build_birkhoff_fw(; seed=seed, build_args...)
        "Spectrahedron" => build_spectrahedron(; seed=seed, build_args...)
        "Sparse"        => build_sparse(; seed=seed, build_args...)
        "Nuclear"       => build_nuclear(; seed=seed, build_args...)
        "A-Criterion"   => build_a_opt(; seed=seed, build_args...)
        "D-Criterion"   => build_d_opt(; seed=seed, build_args...)
        "Poisson"       => build_poisson_fw(; seed=seed, build_args...)
        _               => problem
    end

    bm = run_benchmark_fw( fw, 
                        fw_args, 
                        kwargs=fw_kwargs, 
                        time_tolerance=time_tolerance,
                        memory_tolerance=memory_tolerance,
                        num_runs=num_runs,
                        time_per_run=time_per_run,
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
                            boscia_kwargs=Dict{Symbol, Any}(),
                            time_tolerance=0.05,
                            memory_tolerance=0.01,
                            num_runs=3,
                            time_per_run=60,
                            settings_bnb=Dict{Symbol, Any}(),
                            settings_fw=Dict{Symbol, Any}(),
                            settings_tol=Dict{Symbol, Any}(),
                            settings_pp=Dict{Symbol, Any}(),
                            settings_heur=Dict{Symbol, Any}(),
                            settings_tight=Dict{Symbol, Any}(),
                            settings_domain=Dict{Symbol, Any}(),
                            settings_mode=Dict{Symbol, Any}(),
                            )
    # FW variant to use
    fw_algo = @match fw begin
        "BPCG"              => Boscia.BlendedPairwiseConditionalGradient()
        "Vanilla"           => Boscia.StandardFrankWolfe()
        "Away"              => Boscia.AwayFrankWolfe()
        "BCG"               => Boscia.BlendedConditionalGradient()
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
    # boscia_kwargs   = convert(Dict{Symbol, Any}, boscia_kwargs)
    boscia_kwargs[:variant] = fw_algo

    # build and evaluate benchmark run
    bm = run_benchmark_boscia( Boscia.solve, 
                        boscia_args, 
                        kwargs=boscia_kwargs,
                        time_tolerance=time_tolerance,
                        memory_tolerance=memory_tolerance,
                        num_runs=num_runs,
                        time_per_run=time_per_run,
                        settings_bnb=settings_bnb,
                        settings_fw=settings_fw,
                        settings_tol=settings_tol,
                        settings_pp=settings_pp,
                        settings_heur=settings_heur,
                        settings_tight=settings_tight,
                        settings_domain=settings_domain,
                        settings_mode=settings_mode,
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
function run_benchmark_fw( func, 
                        args; 
                        kwargs=Dict{Symbol, Any}(), 
                        time_tolerance=0.05, 
                        memory_tolerance=0.01,
                        num_runs=10,
                        time_per_run=3600,
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
    max_trajectory  = Vector{Any}([])

    # needed for building trial
    gctimes         = Vector{Float64}([])
    allocs          = Vector{Int64}([])

    if num_runs === nothing
        num_runs = 10
    end

    if time_per_run === nothing
        time_per_run = 3600
    end
    
    trajectory = []

    for _ in 1:num_runs
        dual_gap = 0.0
        track_lmo.counter = 0
        track_grad!.counter = 0
        track_f.counter = 0
        global evaluated = @benchmark begin 
            global _, _, _, dual_gap, trajectory = $func($track_f, $track_grad!, $track_lmo, copy($x0); max_iteration=Inf, timeout=$time_per_run, epsilon=1e-7, verbose=true, trajectory=true, $kwargs...) 
        end samples=1 evals=1 seconds=(time_per_run) time_tolerance=time_tolerance memory_tolerance=memory_tolerance

        if length(trajectory) > length(max_trajectory)
            println("New max trajectory length: $(length(trajectory))")
            max_trajectory = trajectory
        end

        # TODO: handle trajectory having different lengths for each run (in case of timeout)

        # Tracking is done once each for eval run and taken sample, so need to half. Rounding for runs that timeout, since they may slightly differ in LMO calls
        push!(obj_counts, Int(round(track_f.counter / 2)))
        push!(lmo_counts, Int(round(track_lmo.counter / 2)))
        push!(grad_counts, Int(round(track_grad!.counter / 2)))
        push!(dual_gaps, Float64(dual_gap))
        

        push!(times, Float64(evaluated.times[1])) 
        push!(gctimes, Float64(evaluated.gctimes[1]))

        push!(memory, evaluated.memory)
        push!(allocs, evaluated.allocs)

        global trajectory = []
    end

    params = evaluated.params
    params.samples = num_runs
    params.evals=1
    params.seconds=time_per_run

    bm = BenchmarkTools.Trial(params, times, gctimes, maximum(memory), maximum(allocs))

    return bm, obj_counts, grad_counts, lmo_counts, dual_gaps, memory ./ 1e9, times ./ 1e9, max_trajectory
end;


function run_benchmark_boscia( 
    func, 
    args; 
    kwargs=Dict{Symbol, Any}(), 
    time_tolerance=0.05, 
    memory_tolerance=0.01,
    num_runs=10,
    time_per_run=3600,
    settings_bnb=Dict{Symbol, Any}(),
    settings_fw=Dict{Symbol, Any}(),
    settings_tol=Dict{Symbol, Any}(),
    settings_pp=Dict{Symbol, Any}(),
    settings_heur=Dict{Symbol, Any}(),
    settings_tight=Dict{Symbol, Any}(),
    settings_domain=Dict{Symbol, Any}(),
    settings_mode=Dict{Symbol, Any}(),
    )

    f, grad! = args[1], args[2]
    new_args = [args[i] for i in 3:length(args)]
    track_f = FrankWolfe.TrackingObjective(f);
    track_grad! = FrankWolfe.TrackingGradient(grad!)
    prepend!(new_args, [track_f, track_grad!])
    @assert length(new_args) == length(args)
    # track_lmo = FrankWolfe.TrackingLMO(lmo)

    obj_counts      = Vector{Int64}([])
    lmo_counts      = Vector{Int64}([])
    grad_counts     = Vector{Int64}([])
    memory          = Vector{Int64}([])
    times           = Vector{Float64}([])

    # needed for building trial
    gctimes         = Vector{Float64}([])
    allocs          = Vector{Int64}([])

    if num_runs === nothing
        num_runs = 10
    end

    if time_per_run === nothing
        time_per_run = 3600
    end

    # create settings for Boscia
    bnb = Boscia.settings_bnb()
    fw = Boscia.settings_frank_wolfe()
    tolerances = Boscia.settings_tolerances()
    postprocessing = Boscia.settings_postprocessing()
    heuristic = Boscia.settings_heuristic()
    tightening = Boscia.settings_tightening()
    domain = Boscia.settings_domain()
    mode = Dict(:mode => Boscia.DEFAULT_MODE)

    for key in keys(settings_bnb)
        bnb[Symbol(key)] = settings_bnb[Symbol(key)]
    end
    for key in keys(settings_fw)
        fw[Symbol(key)] = settings_fw[Symbol(key)]
    end
    for key in keys(settings_tol)
        tolerances[Symbol(key)] = settings_tol[Symbol(key)]
    end
    for key in keys(settings_pp)
        postprocessing[Symbol(key)] = settings_pp[Symbol(key)]
    end
    for key in keys(settings_heur)
        heuristic[Symbol(key)] = settings_heur[Symbol(key)]
    end
    for key in keys(settings_tight)
        tightening[Symbol(key)] = settings_tight[Symbol(key)]
    end
    for key in keys(settings_domain)
        domain[Symbol(key)] = settings_domain[Symbol(key)]
    end
    for key in keys(settings_mode)
        mode[Symbol(key)] = settings_mode[Symbol(key)]
    end

    # time limit and FW variant are overwritten by separate parameters
    bnb[:time_limit] = time_per_run
    bnb[:verbose] = true
    fw[:variant] = kwargs[:variant]

    settings = (
        branch_and_bound = bnb,
        frank_wolfe = fw,
        tolerances = tolerances,
        postprocessing = postprocessing,
        heuristic = heuristic,
        tightening = tightening,
        domain = domain,
        mode = mode,
    )

    lmo_output = nothing
    result = Dict{Symbol, Any}()
    max_lb = Vector{Float64}([])
    max_ub = Vector{Float64}([])
    solve_times = Vector{Float64}([])
    lmo_calls = Vector{Int64}([])
    lmo_per_layer = Vector([])
    active_set_sizes = Vector([])
    active_set_per_layer = Vector([])
    discarded_set_sizes = Vector([])
    discarded_set_per_layer = Vector([])

    for _ in 1:num_runs
        track_grad!.counter = 0
        track_f.counter = 0

        global evaluated = @benchmark begin 
            global _, lmo_output, result = $func($(new_args)...; settings=$settings) 
        end samples=1 evals=1 seconds=(time_per_run * 1.05) time_tolerance=time_tolerance memory_tolerance=memory_tolerance

        # Update max lower and upper bounds. Both have the same length
        if length(result[:list_lb]) > length(max_lb) 
            max_lb = result[:list_lb]
            max_ub = result[:list_ub]
            solve_times = result[:list_time]
            lmo_calls = result[:lmo_calls]
            lmo_per_layer = result[:lmo_calls_per_layer]
            active_set_sizes = result[:list_active_set_size]
            active_set_per_layer = result[:active_set_size_per_layer]
            discarded_set_sizes = result[:list_discarded_set_size]
            discarded_set_per_layer = result[:discarded_set_size_per_layer]
        end

        # Tracking is done once each for eval run and taken sample, so need to half. Rounding for runs that timeout, since they may slightly differ in LMO calls
        push!(obj_counts, Int(round(track_f.counter / 2)))
        push!(lmo_counts, Int(round(lmo_output.ncalls / 2)))
        push!(grad_counts, Int(round(track_grad!.counter / 2)))
        
        push!(times, Float64(evaluated.times[1])) 
        push!(gctimes, Float64(evaluated.gctimes[1]))

        push!(memory, evaluated.memory)
        push!(allocs, evaluated.allocs)

        global result = Dict{Symbol, Any}()
        global lmo_output = nothing
    end

    params = evaluated.params
    params.samples = num_runs
    params.evals=1
    params.seconds=time_per_run

    bm = BenchmarkTools.Trial(params, times, gctimes, maximum(memory), maximum(allocs))

    return (
        bm, 
        obj_counts, 
        grad_counts, 
        lmo_counts, 
        max_lb, 
        max_ub, 
        memory ./ 1e9, 
        times ./ 1e9, 
        solve_times ./ 1000, 
        lmo_calls, 
        lmo_per_layer, 
        active_set_sizes, 
        active_set_per_layer, 
        discarded_set_sizes, 
        discarded_set_per_layer,
    )
end;