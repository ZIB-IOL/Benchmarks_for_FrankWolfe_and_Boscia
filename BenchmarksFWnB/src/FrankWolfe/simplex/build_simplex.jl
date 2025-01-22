"""
Builds 1/m ||Ax + b||^2 objective and Simplex LMO with dimension n and given radius.
"""
function build_simplex(; m=100, n=30, radius=1.0, active=false, seed=1234)
    rng = StableRNG(seed)
    
    A = Random.randn(rng, m, n)
    b = Random.randn(rng, m)

    A_sq = 2/m * (transpose(A) * A)
    A_b = 2/m * (transpose(A) * b)
    b_squared = 2/m * (transpose(b) * b)

    f(x) = (1/2) * (transpose(x) * A_sq * x) + (transpose(x) * A_b) + (1/2) * b_squared
    grad!(storage, x) = storage .= A_sq * x + A_b

    lmo = FrankWolfe.ProbabilitySimplexOracle(radius)
    x0 = compute_extreme_point(lmo, zeros(Float64, n))

    if convert(Bool, active) == true
        active_set = FrankWolfe.ActiveSetQuadraticProductCaching([(BigFloat(1.0), copy(x0))], A' * A, A' * b)
        return f, grad!, lmo, active_set
    end

    return f, grad!, lmo, x0
end;
