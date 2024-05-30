"""
Builds and returns the BirkhoffPolytopeLMO and a starting point.
"""
function build_birkhoff_lmo(; n=10, seed=1234)
    rng = StableRNG(seed)

    lmo = FrankWolfe.BirkhoffPolytopeLMO()
    x0 = compute_extreme_point(lmo, reshape(randn(rng, n*n), n, n))

    return lmo, x0
end

"""
Builds the objective function as in birkhoff_polytope example in FrankWolfe.jl
"""
function build_birkhoff_obj(; n=10, seed=1234)
    rng = StableRNG(seed)
    
    xpi = rand(rng, n*n)
    xpi = reshape(xpi, n, n)

    function f(x)
        return norm(x .- xpi)^2 / n^2
    end

    function grad!(storage, x)
        return @. storage = (2 * (x - xpi)) / n^2
    end
    return f, grad!
end