"""
Builds K-sparse polytope.

# Arguments
- 'K': number of values
- 'rhs': value of the right-hand side

# Returns
- 'lmo': FrankWolfe.KSparseLMO(K, rhs)
- 'x0': extreme point of 'lmo'

# Reference: https://github.com/ZIB-IOL/FrankWolfe.jl/blob/e880f9f7785b332504f597b874b9101cfe6ebce1/src/polytope_oracles.jl
"""
function build_sparse_lmo(; K=40, dim=100, rhs=1.0)
    lmo = FrankWolfe.KSparseLMO(K, rhs)
    x0 = compute_extreme_point(lmo, zeros(dim))
    return lmo, x0
end

"""
Builds objective function as in K-sparse polytope example. 

# Arguments
- 'n': dimension of the problem
- 'seed': random seed

# Returns
- 'f': objective function
- 'grad!': gradient of f

# Reference: https://github.com/ZIB-IOL/FrankWolfe.jl/blob/e880f9f7785b332504f597b874b9101cfe6ebce1/examples/alm.jl 
"""
function build_sparse_obj(; n=100, seed=1234)
    rng = StableRNG(seed)

    xpi = rand(rng, 1:100, n)
    total = sum(xpi)
    xp = xpi .// total

    f(x) = FrankWolfe.fast_dot(x - xp, x - xp)

    function grad!(storage, x)
        @. storage = 2 * (x - xp)
    end

    return f, grad!
end