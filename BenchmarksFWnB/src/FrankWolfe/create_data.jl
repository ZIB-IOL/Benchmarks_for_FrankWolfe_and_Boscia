using FrankWolfe
using Match
using Random

function create_data(fw_alg, lmo, obj, dim, seed=1234)
    rng = MersenneTwister(seed)

    fw_alg = @match fw_alg begin
        "vanilla" => frank_wolfe
        "away" => away_frank_wolfe
        "blended" => blended_conditional_gradient
        "blended_pairwise" => FrankWolfe.blended_pairwise_conditional_gradient
    end

    lmo, x0 = @match lmo begin
        "ProbSimplex" => SetupFrankWolfe.build_simplex(dim, seed)
        "LpNorm" => ("hey", "hey")
        _ => BenchmarksFWnB.SetupFrankWolfe.build_simplex(dim, seed)
    end

    f, grad! = @match obj begin
        "random matrix sq norm" => SetupFrankWolfe.build_random(dim, seed)
        "abs_sum" => abs_sum()
        _ => abs_sum()
    end
    
    return fw_alg, f, grad!, lmo, x0
end;
