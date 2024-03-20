function build_simplex(; dim=3, seed=1234)
    rng = Random.MersenneTwister(seed)
    radius = rand(rng, 1:100)
    lmo = FrankWolfe.ProbabilitySimplexOracle(radius)
    x0 = compute_extreme_point(lmo, zeros(Float64, dim))
    return lmo, x0
end;