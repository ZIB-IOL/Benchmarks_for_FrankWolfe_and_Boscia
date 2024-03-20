function create_data_FW(fw_alg, lmo, obj, dim; seed=1234)
    rng = MersenneTwister(seed)

    fw_alg = @match fw_alg begin
        "vanilla" => frank_wolfe
        "away" => away_frank_wolfe
        "blended" => blended_conditional_gradient
        "blended_pairwise" => FrankWolfe.blended_pairwise_conditional_gradient
        _ => frank_wolfe  # default to frank_wolfe for now
    end

    lmo, x0 = @match lmo begin
        "simplex" => SetupFrankWolfe.build_simplex(dim, seed=seed)
        "nuclear" => SetupFrankWolfe.build_nuclear_lmo(dim)
        _ => SetupFrankWolfe.build_simplex(dim, seed=seed)
    end

    f, grad! = @match obj begin
        "random MSE" => SetupFrankWolfe.build_random(dim, seed=seed)
        "nuclear" => SetupFrankWolfe.build_nuclear_obj(dim, seed=seed)
        "abs_sum" => SetupFrankWolfe.build_abs_sum()
        _ => SetupFrankWolfe.build_abs_sum()
    end
    
    return fw_alg, f, grad!, lmo, x0
end;
