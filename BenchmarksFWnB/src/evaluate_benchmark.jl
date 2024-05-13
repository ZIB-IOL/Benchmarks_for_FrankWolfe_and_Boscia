"""
Sets up benchmark for FrankWolfe, evaluates the run and returns the benchmark. 

    # Arguments
    - 'fw': Frank-Wolfe variant to use. Choose from:    "BPCG"
                                                        "Vanilla" 
                                                        "Away" 
                                                        "BCG"
                                                        "Lazy"
                                                        "PCG"
                                                        Frank-Wolfe function

    - 'lmo': LMO over which to optimize. Choose from:   "Simplex"
                                                        "Nuclear"
                                                        "Spectrahedron"
                                                        "Birkhoff"
                                                        "Sparse"
                                                        (lmo, x0) tuple for custom lmo and starting point

    - 'obj': objective function to optimize. Choose from:   "MSE"
                                                            "Nuclear"
                                                            "Spectrahedron"
                                                            "Birkhoff"
                                                            "Sparse"
                                                            (f, grad!) tuple for custom objective
                                                            
    - 'lmo_args': arguments for lmo that can be passed by unpacking
    - 'obj_args': arguments for objective that can be passed by unpacking
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
                        fw="vanilla", 
                        lmo="simplex", 
                        obj="MSE", 
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
        "Vanilla"       => frank_wolfe
        "BCG"           => blended_conditional_gradient
        "BPCG"          => FrankWolfe.blended_pairwise_conditional_gradient
        "Away"          => away_frank_wolfe
        "PCG"           => FrankWolfe.pairwise_frank_wolfe
        "Lazy"          => lazified_conditional_gradient
        _               => fw
    end

    # lmo 
    lmo, x0 = @match lmo begin
        "Simplex"       => build_simplex(; lmo_args..., seed=seed)
        "Birkhoff"      => build_birkhoff_lmo(; lmo_args..., seed=seed)
        "Spectrahedron" => build_spectrahedron_lmo(; lmo_args...)
        "Sparse"        => build_sparse_lmo(; lmo_args...)
        "Nuclear"       => build_nuclear_lmo(; lmo_args...)
        _               => lmo
    end

    # objective
    f, grad! = @match obj begin 
        "MSE"           => build_random(; obj_args..., seed=seed)
        "Birkhoff"      => build_birkhoff_obj(; obj_args..., seed=seed)
        "Spectrahedron" => build_spectrahedron_obj(; obj_args..., seed=seed)
        "Sparse"        => build_sparse_obj(; obj_args..., seed=seed)
        "Nuclear"       => build_nuclear_obj(; obj_args..., seed=seed)
        _               => obj
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
        "BPCG"              => Boscia.BPCG()
        "Vanilla"           => Boscia.VanillaFrankWolfe()
        "Away"              => Boscia.AwayFrankWolfe()
        "BCG"               => Boscia.Blended()
        _                   => Boscia.BPCG()
    end

    # create args for 'Boscia.solve'
    args = @match problem begin
        "CubeSimpleInt"     => build_cube_simple_integer(; build_args..., seed=seed)
        "CubeSimpleMix"     => build_cube_simple_mixed(; build_args..., seed=seed)
        "Birkhoff"          => build_birkhoff_boscia(; build_args..., seed=seed)
        "SparseReg"         => build_sparse_reg(; build_args..., seed=seed)
        "Poisson"           => build_poisson_reg(; build_args..., seed=seed)
        "Portfolio"         => build_portfolio(; build_args..., seed=seed)
        "Lasso"             => build_lasso(; build_args..., seed=seed)
        _                   => build_cube_simple_integer(; build_args..., seed=seed)
    end

    # Boscia args and kwargs
    boscia_args     = [args...]
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
