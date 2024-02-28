using FrankWolfe

function abs_sum() 
    f(x) = sum(abs2, x)
    grad!(storage, x) = storage .= 2x
    return f, grad!
end

function build_random(dim, seed)
    rng = MersenneTwister(seed)
    A = rand(rng, 5*dim, dim)
    b = rand(rng, 5*dim)
    
    m = 5*dim

    A_sq = 2/m * transpose(A) * A
    A_b = 2/m * transpose(A) * b
    b_squared = 2/m * transpose(b) * b

    f(x) = (1/2) * (transpose(x) * A_sq * x) + (transpose(x) * A_b) + (1/2) * b_squared
    grad!(storage, x) = storage .= A_sq * x + A_b

    return f, grad!
end
