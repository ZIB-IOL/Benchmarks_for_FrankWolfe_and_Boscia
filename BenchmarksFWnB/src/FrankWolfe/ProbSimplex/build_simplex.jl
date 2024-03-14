function build_simplex(dim=3, radius=1)
    lmo = FrankWolfe.ProbabilitySimplexOracle(radius)
    x0 = compute_extreme_point(lmo, zeros(Float64, dim))
    return lmo, x0
end