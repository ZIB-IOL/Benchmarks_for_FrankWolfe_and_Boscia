function build_birkhoff_fw(; n=100, k=3000, seed=1234)
    rng = MersenneTwister(seed)
    
    xpi = rand(rng, n*n)
    total = sum(xpi)
    xpi = reshape(xpi, n, n)

    function cf(x, xp)
        return LinearAlgebra.norm(x .- xp)^2 / n^2
    end

    function cgrad!(storage, x, xp)
        return @. storage = 2 * (x - xp) / n^2
    end

    lmo = FrankWolfe.BirkhoffPolytopeLMO()
    x0 = compute_extreme_point(lmo, reshape(randn(rng, n*n), n, n))

    return cf, cgrad!, lmo, x0
end