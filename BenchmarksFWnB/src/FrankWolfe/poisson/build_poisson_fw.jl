"""
Builds data for poisson_reg example for Boscia
    min_{w, b, z} ∑_i exp(w x_i + b) - y_i (w x_i + b) + α norm(w)^2
    s.t. -N z_i <= w_i <= N z_i
    b ∈ [-N, N]
    z_i ∈ {0,1} for i = 1,..,p

    y_i    - data points, poisson distributed 
    X_i, b - coefficient for the linear estimation of the expected value of y_i
    w_i    - continuous variables
    k      - max number of non zero entries in w
"""
function build_poisson_fw(; n=20, seed=1234)
    rng = StableRNG(seed)

    p = n

    ws = rand(rng, p)

    # set some ws to zero
    for _ in 1:n
        ws[rand(rng, 1:p)] = 0
    end

    bs = rand(rng)
    Xs = rand(rng, n, p)
    ys = map(1:n) do idx
        a = dot(Xs[idx, :], ws) + bs
        return rand(rng, Distributions.Poisson(exp(a) / exp(n/2)))
    end

    Ns = 0.1

    # lmo
    o = SCIP.Optimizer()
    MOI.set(o, MOI.Silent(), true)
    MOI.empty!(o)
    w = MOI.add_variables(o, p)
    b = MOI.add_variable(o)

    # w vars between -Nz and Nz
    for i in 1:p
        MOI.add_constraint(o, w[i], MOI.GreaterThan(-Ns))
        MOI.add_constraint(o, w[i], MOI.LessThan(Ns))
    end

    # b constraint 
    MOI.add_constraint(o, b, MOI.LessThan(Ns))
    MOI.add_constraint(o, b, MOI.GreaterThan(-Ns))

    lmo = FrankWolfe.MathOptLMO(o)
    x0 = FrankWolfe.compute_extreme_point(lmo, zeros(p+1))

    # objective
    α = 1.3
    function f(θ)
        w = @view(θ[1:p])
        b = θ[end]
        s = sum(1:n) do i
            a = dot(w, Xs[:, i]) + b
            return 1 / n * (exp(a) - ys[i] * a)
        end
        return s + α * norm(w)^2
    end

    function grad!(storage, θ)
        w = @view(θ[1:p])
        b = θ[end]
        storage[1:p] .= 2α .* w
        storage[end] = 0
        for i in 1:n
            xi = @view(Xs[:, i])
            a = dot(w, xi) + b
            storage[1:p] .+= 1 / n * xi * exp(a)
            storage[1:p] .-= 1 / n * ys[i] * xi
            storage[end] += 1 / n * (exp(a) - ys[i])
        end
        storage ./= norm(storage)
        return storage
    end

    return f, grad!, lmo, convert(SparseArrays.SparseVector, x0)
end
