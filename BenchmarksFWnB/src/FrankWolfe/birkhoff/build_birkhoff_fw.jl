"""
Builds objective and LMO for the Birkhoff problem.
"""
function build_birkhoff_fw(; n=10, active=false, seed=1234)
    rng = StableRNG(seed)
        
    xpi = rand(rng, n*n)
    xpi = reshape(xpi, n, n)

    function f(x)
        return norm(x .- xpi)^2 / n^2
    end

    function grad!(storage, x)
        return @. storage = (2 * (x - xpi)) / n^2
    end

    lmo = FrankWolfe.BirkhoffPolytopeLMO()
    x0 = compute_extreme_point(lmo, reshape(rand(rng, n*n), n, n))

    if convert(Bool, active) == true
        active_set = FrankWolfe.ActiveSetQuadratic([(BigFloat(1.0), x0)], 1/n^2 * 2 * Matrix(I, n, n), -2/100 * xpi)
        return f, grad!, lmo, active_set
    end

    return f, grad!, lmo, x0
end
