"""
Builds Simplex LMO with dimension n and radius.
"""
function build_simplex(; n=3, radius=1.0, seed=1234)
    rng = Random.MersenneTwister(seed)
    lmo = FrankWolfe.ProbabilitySimplexOracle(radius)
    x0 = compute_extreme_point(lmo, zeros(Float64, n))
    return lmo, x0
end

"""
Builds 1/n * ||Ax + b||^2 objective with normally distributed A and b.
"""
function build_random(; n=100, k=30, seed=1234)
    rng = StableRNG(seed)
    
    A = Random.randn(rng, n, k)
    b = Random.randn(rng, n)

    A_sq = 2/n * (transpose(A) * A)
    A_b = 2/n * (transpose(A) * b)
    b_squared = 2/n * (transpose(b) * b)

    f(x) = (1/2) * (transpose(x) * A_sq * x) + (transpose(x) * A_b) + (1/2) * b_squared
    grad!(storage, x) = storage .= A_sq * x + A_b

    return f, grad!
end;