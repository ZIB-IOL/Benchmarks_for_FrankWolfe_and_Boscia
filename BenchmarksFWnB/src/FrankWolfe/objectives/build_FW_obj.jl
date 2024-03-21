"""
Objective in FrankWolfe.jl homepage example.
"""
function build_abs_sum() 
    f(x) = sum(abs2, x)
    grad!(storage, x) = storage .= 2x
    return f, grad!
end;

"""
Builds ||Ax + b||^2 objective with random normally distributed A and b.
"""
function build_random(; n=100, k=30, seed=1234)
    rng = MersenneTwister(seed)
    
    A = Random.randn(rng, n, k)
    b = Random.randn(rng, n)

    A_sq = 2/n * transpose(A) * A
    A_b = 2/n * transpose(A) * b
    b_squared = 2/n * transpose(b) * b

    f(x) = (1/2) * (transpose(x) * A_sq * x) + (transpose(x) * A_b) + (1/2) * b_squared
    grad!(storage, x) = storage .= A_sq * x + A_b

    return f, grad!
end;