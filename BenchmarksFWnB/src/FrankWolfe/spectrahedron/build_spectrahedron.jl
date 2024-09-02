
"""
Builds spectrahedron objective and LMO

# Arguments
- 'range': range of entry values. Also functions as LMO dim
- 'entries': number of known entries

# Return 
- 'f': objective function
- 'grad!': gradient of f
- 'lmo': FrankWolfe.SpectraplexLMO of dimension 'range'
- 'x0': starting vertex

Reference: https://github.com/ZIB-IOL/FrankWolfe.jl/blob/35033927971290f42dbb0ea1f924d4c1f74f1524/examples/docs_6_spectrahedron.jl#L2 
"""
function build_spectrahedron(; entries=1000, range=1500, radius=1.0, seed=1234)
    rng = StableRNG(seed)
    
    n = range

    entry_indices = unique!([minmax(rand(rng, 1:range, 2)...) for _ in 1:entries])
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

    return f, grad!, lmo, x0
end
