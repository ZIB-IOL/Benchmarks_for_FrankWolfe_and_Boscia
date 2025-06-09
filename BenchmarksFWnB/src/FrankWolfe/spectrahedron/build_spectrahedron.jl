
"""
Builds spectrahedron objective and LMO

# Arguments
- 'n': range of entry values. Also functions as LMO dim
- 'entries': number of known entries

# Return 
- 'f': objective function
- 'grad!': gradient of f
- 'lmo': FrankWolfe.SpectraplexLMO of dimension n
- 'x0': starting vertex

Reference: https://github.com/ZIB-IOL/FrankWolfe.jl/blob/35033927971290f42dbb0ea1f924d4c1f74f1524/examples/docs_6_spectrahedron.jl#L2 
"""
function build_spectrahedron(; entries=1000, n=1500, radius=1.0, active=false, seed=1234)
    rng = StableRNG(seed)

    entry_indices = unique!([minmax(rand(rng, 1:n, 2)...) for _ in 1:entries])
    entry_values = randn(rng, length(entry_indices))

    function f(X)
        r = zero(eltype(X))
        for (idx, (i, j)) in enumerate(entry_indices)
            r += 1 / 2 * (X[i, j] - entry_values[idx])^2
            r += 1 / 2 * (X[j, i] - entry_values[idx])^2
        end
        return r / length(entry_values)
    end

    function grad!(storage, X)
        storage .= 0
        for (idx, (i, j)) in enumerate(entry_indices)
            storage[i, j] += (X[i, j] - entry_values[idx])
            storage[j, i] += (X[j, i] - entry_values[idx])
        end
        return storage ./= length(entry_values)
    end

    lmo = FrankWolfe.SpectraplexLMO(radius, n, false)
    x0 = compute_extreme_point(lmo, spzeros(n, n))

    if convert(Bool, active) == true
        present_mat = zeros(n, n)
        present_b = zeros(n, n)
        for (idx, (i, j)) in enumerate(entry_indices)
            if i == j 
                present_mat[i, j] = 1
            end
            present_b[i, j] = -entry_values[idx]
            present_b[j, i] = -entry_values[idx]
        end
        return f, grad!, lmo, FrankWolfe.ActiveSetQuadraticProductCaching([(1.0, x0)], present_mat, present_b)
    end

    return f, grad!, lmo, x0
end
