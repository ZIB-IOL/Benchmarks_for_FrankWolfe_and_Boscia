function build_nuclear_obj(; n=500, k=30, seed=1234)
    rng = MersenneTwister(seed)

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

    # def nuc-norm 
    nucnorm(Xmat) = sum(abs(σi) for σi in svdvals(Xmat))
    
    missing_entries = unique!([(rand(1:nobs), rand(1:nfeat)) for _ in 1:10000])
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
    return f, grad!
end;

function build_nuclear_lmo(; n=500)
    lmo = FrankWolfe.NuclearNormLMO(275_000.0)
    x0 = compute_extreme_point(lmo, zeros(Float64, n, n))
    return lmo, x0
end;

function build_nuclear(; n=500, k=30, seed=1234)
    f, grad! = build_nuclear_obj(n=n, k=k, seed=seed)
    lmo, x0 = build_nuclear_lmo(n=n)
    return f, grad!, lmo, x0
end;
