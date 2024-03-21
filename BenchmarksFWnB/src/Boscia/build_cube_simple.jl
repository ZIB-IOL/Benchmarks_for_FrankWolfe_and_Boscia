"""
Builds data according to 'Cube Simple LMO' example in 'approx_planted_point.jl' for Boscia, integer version.
"""
function build_cube_simple_integer(
                                    ;
                                    n=20,
                                    seed=1234,
                                  )
    rng = MersenneTwister(seed)

    diffi = rand(rng, Bool, n) * 0.6 .+ 0.3

    function f(x)
        return 0.5 * sum((x[i] - diffi[i])^2 for i in eachindex(x))
    end

    function grad!(storage, x)
        @. storage = x - diffi
    end

    int_vars = collect(1:n)
    lbs = zeros(n)
    ubs = ones(n)

    lmo = Boscia.CubeSimpleBLMO(lbs, ubs, int_vars)

    return f, grad!, lmo
end;

"""
Builds data according to 'Cube Simple LMO' example in 'approx_planted_point.jl' for Boscia, mixed version.
"""
function build_cube_simple_mixed(   
                                ;
                                n=20,
                                seed=1234,
                                )
    rng = MersenneTwister(seed)

    diffi = rand(rng, Bool, n) * 0.6 .+ 0.3
    
    function f(x)
        return 0.5 * sum((x[i] - diffi[i])^2 for i in eachindex(x))
    end

    function grad!(storage, x)
        @. storage = x - diffi
    end

    int_vars = unique!(rand(collect(1:n), Int(floor(n / 2))))

    lbs = zeros(n)
    ubs = ones(n)

    lmo = Boscia.CubeSimpleBLMO(lbs, ubs, int_vars)

    return f, grad!, lmo
end;