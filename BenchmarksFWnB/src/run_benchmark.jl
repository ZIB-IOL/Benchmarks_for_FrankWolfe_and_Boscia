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
    return benchmarkable, evaluated
end;

function compare_benchmarks(bm1, bm2; time_tolerance=0.05, memory_tolerance=0.01)
    median1 = median(bm1)
    median2 = median(bm2)
    println("MEDIAN COMPARISON:")
    display(judge(median1, median2, time_tolerance=time_tolerance, memory_tolerance=memory_tolerance))
end;

function benchmark_FW(; 
                        fw="vanilla", 
                        lmo="simplex", 
                        obj="random MSE", 
                        dim=10, 
                        seed=1234, 
                        fw_kwargs=[],
                        seconds=3600,
                        evals=5,
                        samples=10,
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
        lmo, x0 = build_nuclear_lmo(; dim=dim)
        f, grad! = build_nuclear_obj(; dim=dim, seed=seed)
    else
        lmo, x0 = @match lmo begin
            "simplex" => build_simplex(dim=dim, seed=seed)
            "LpNorm" => FrankWolfe.LpNormLMO{rand(MersenneTwister(seed), 1:100)}(rand(MersenneTwister(seed), 1:10))
            _ => build_simplex(dim=dim, seed=seed)
        end
        f, grad! = @match obj begin 
            "random MSE" => build_random(dim=dim, seed=seed)
            "abs sum" => build_abs_sum()
            _ => build_random(dim=dim, seed=seed)
        end
    end

    fw_args = [f, grad!, lmo, x0]
    bmkbl, bm = run_benchmark(fw, 
                              fw_args, 
                              kwargs=fw_kwargs, 
                              seconds=seconds,
                              evals=evals,
                              samples=samples,
                              time_tolerance=time_tolerance,
                              memory_tolerance=memory_tolerance,
                              )
    return bmkbl, bm
end;