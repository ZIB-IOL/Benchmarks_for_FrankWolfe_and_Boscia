
"""
Builds objective function as in K-sparse polytope example. 

# Arguments
- 'n': dimension of the problem
- 'K': number of values
- 'rhs': value of the right-hand side
- 'seed': random seed

# Returns
- 'f': objective function
- 'grad!': gradient of f

# Reference: https://github.com/ZIB-IOL/FrankWolfe.jl/blob/e880f9f7785b332504f597b874b9101cfe6ebce1/examples/alm.jl 
"""
function build_sparse(; n=100, K=40, rhs=1.0, active=false, seed=1234)
    rng = StableRNG(seed)

    xpi = rand(rng, 1:100, n)
    total = sum(xpi)
    xp = 1.0 * (xpi .// total)

    f(x) = FrankWolfe.fast_dot(x - xp, x - xp)

    function grad!(storage, x)
        @. storage = 2 * (x - xp)
    end

    lmo = FrankWolfe.KSparseLMO(K, rhs)
    x0 = compute_extreme_point(lmo, zeros(n))

    if convert(Bool, active) == true
        active_set = FrankWolfe.ActiveSetQuadraticProductCaching([(1.0, x0)], LinearAlgebra.I, -2*xp)
        return f, grad!, lmo, active_set
    end

    return f, grad!, lmo, x0
end