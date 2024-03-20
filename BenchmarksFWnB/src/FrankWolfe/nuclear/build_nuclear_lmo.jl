function build_nuclear_lmo(; dim=10)
    lmo = FrankWolfe.NuclearNormLMO(275_000.0)
    x0 = compute_extreme_point(lmo, zeros(Float64, 5 * dim, 5 * dim))
    return lmo, x0
end;
