"""
Builds data for poisson_reg example for Boscia
    min_{w, b, z} ∑_i exp(w x_i + b) - y_i (w x_i + b) + α norm(w)^2
    s.t. -N z_i <= w_i <= N z_i
    b ∈ [-N, N]
    ∑ z_i <= k 
    z_i ∈ {0,1} for i = 1,..,p

    y_i    - data points, poisson distributed 
    X_i, b - coefficient for the linear estimation of the expected value of y_i
    w_i    - continuous variables
    z_i    - binary variables s.t. z_i = 0 => w_i = 0
    k      - max number of non zero entries in w

    In a poisson regression, we want to model count data.
    It is assumed that y_i is poisson distributed and that the log 
    of its expected value can be computed linearly.

Reference: https://github.com/ZIB-IOL/Boscia.jl/blob/main/examples/poisson_reg.jl 
"""
function build_poisson_reg(; n=20, p=20, k=10, seed=1234)
    rng = StableRNG(seed)

    ws = rand(rng, p)

    # set some ws to zero
    for _ in 1:n
        ws[rand(rng, 1:p)] = 0
    end

    bs = rand(rng)
    Xs = rand(rng, n, p)
    ys = map(1:n) do idx
        a = dot(Xs[idx, :], ws) + bs
        return rand(rng, Distributions.Poisson(exp(a)))
    end

    Ns = 0.1

    # lmo
    o = SCIP.Optimizer()
    MOI.set(o, MOI.Silent(), true)
    MOI.empty!(o)
    w = MOI.add_variables(o, p)
    z = MOI.add_variables(o, p)
    b = MOI.add_variable(o)

    # z = {0, 1} variables
    for i in 1:p
        MOI.add_constraint(o, z[i], MOI.GreaterThan(0.0))
        MOI.add_constraint(o, z[i], MOI.LessThan(1.0))
        MOI.add_constraint(o, z[i], MOI.ZeroOne())
    end

    # w vars between -Nz and Nz
    for i in 1:p
        MOI.add_constraint(o, Ns * z[i] + w[i], MOI.GreaterThan(0.0))
        MOI.add_constraint(o, -Ns * z[i] + w[i], MOI.LessThan(0.0))
    end

    # use more than 1 but less than k z-variables
    MOI.add_constraint(o, sum(z, init=0.0), MOI.LessThan(1.0 * k))
    MOI.add_constraint(o, sum(z, init=0.0), MOI.GreaterThan(1.0))

    # b constraint 
    MOI.add_constraint(o, b, MOI.LessThan(Ns))
    MOI.add_constraint(o, b, MOI.GreaterThan(-Ns))

    lmo = FrankWolfe.MathOptLMO(o)

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
        storage[p+1:2p] .= 0
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

    return f, grad!, lmo
end