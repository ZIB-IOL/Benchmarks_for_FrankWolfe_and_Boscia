"""
Builds data for portfolio example for Boscia.

Reference: https://github.com/ZIB-IOL/Boscia.jl/blob/main/examples/portfolio.jl 
"""
function build_portfolio(; n=30, seed=1234)
    rng = StableRNG(seed)

    ri = rand(rng, n)
    ai = rand(rng, n)
    oi = rand(rng, Float64)
    bi = sum(ai)

    Ai = randn(rng, n, n)
    Ai = Ai' * Ai

    Mi = (Ai + Ai') / 2
    
    @assert isposdef(Mi)

    # lmo
    o = SCIP.Optimizer()
    MOI.set(o, MOI.Silent(), true)
    MOI.empty!(o)
    x = MOI.add_variables(o, n)

    # x positive Integer
    for i in 1:n
        MOI.add_constraint(o, x[i], MOI.GreaterThan(0.0))
        MOI.add_constraint(o, x[i], MOI.Integer())
    end

    MOI.add_constraint(
        o,
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(ai, x), 0.0),
        MOI.LessThan(bi),
    )
    MOI.add_constraint(
        o,
        MOI.ScalarAffineFunction(MOI.ScalarAffineTerm.(ones(n), x), 0.0),
        MOI.GreaterThan(1.0),
    )
    
    lmo = FrankWolfe.MathOptLMO(o)

    # objective
    function f(x)
        return 1/2 * oi * dot(x, Mi, x) - dot(ri, x)
    end

    function grad!(storage, x)
        mul!(storage, Mi, x, oi, 0)
        storage .-= ri
        return storage
    end

    return f, grad!, lmo
end;