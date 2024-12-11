
"""
Builds NuclearNormLMO with upper bound 'rhs', and Nuclear objective (collaborative filtering) 
with a random matrix of dimension n^2 and rank k.
"""
function build_nuclear(; n=50, k=10, rhs=275_000, active=false, seed=1234)
    rng = StableRNG(seed)

    # dimension
    nfeat = n
    nobs = n

    # rank
    r = Integer(k)

    Xreal = Matrix{Float64}(undef, nobs, nfeat)

    X_gen_cols = randn(rng, nfeat, r)
    X_gen_rows = randn(rng, r, nobs)
    svals = 100 * rand(rng, r)

    for i in 1:nobs
        for j in 1:nfeat
            Xreal[i, j] = sum(X_gen_cols[j, k] * X_gen_rows[k, i] * svals[k] for k in 1:r)
        end
    end
    
    @assert rank(Xreal) == r

    missing_entries = unique!([(rand(rng, 1:nobs), rand(rng, 1:nfeat)) for _ in 1:10000])
    present_entries = [(i, j) for i in 1:nobs, j in 1:nfeat if (i, j) ∉ missing_entries]

    # objective and gradient 
    f(X) = 0.5 * sum((X[i, j] - Xreal[i, j])^2 for (i, j) in present_entries)

    function grad!(storage, X)
        storage .= 0
        for (i, j) in present_entries
            storage[i, j] = X[i, j] - Xreal[i, j]
        end
        return nothing
    end

    lmo = FrankWolfe.NuclearNormLMO(rhs)
    x0 = compute_extreme_point(lmo, zeros(Float64, n, n))
    
    if convert(Bool, active) == true
        present_mat = zeros(n, n)
        present_b = zeros(n, n)
        for (i, j) in present_entries
            if i == j 
                present_mat[i, j] = 1
            end
            present_b[i, j] = -Xreal[i, j]
        end
        active_set = FrankWolfe.ActiveSetQuadratic([(1.0, x0)], present_mat, present_b)
        return f, grad!, lmo, active_set
    end

    return f, grad!, lmo, x0
end;
