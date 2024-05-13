# Benchmarks_for_FrankWolfe_and_Boscia
Benchmarks for the FrankWolfe.jl and Boscia.jl packages

## Quick guide
Individual benchmarks can be run by the functions `benchmark_Boscia` and `benchmark_FW` for `Boscia` and `FrankWolfe`, respectively. These return an evaluated benchmark run which is returned and can be displayed by itself. An arbitrary `Frank-Wolfe variant`, `objective` and `LMO` can be passed as well in the form of the function `fw_algo` or tuples `(f, grad!)` and `(lmo, x0)`, respectively.

```julia
# standard version
bm = benchmark_FW(fw="BPCG", obj=(f, grad!), lmo=(lmo, x0))


# with custom stuff
function some_custom_frank_wolfe(f, grad!, lmo, x0; kwargs)
# ...
end

function f(x)
# objective function
end

function grad!(storage, x)
# gradient of f
end

lmo = some_LMO()
x0 = compute_extreme_point(lmo, zeros(dim))

new_benchmark = benchmark_FW(fw=some_custom_frank_wolfe, obj=(f, grad!), lmo=(lmo, x0))
```

### Compare all
By passing the computed benchmark to `compare_all_Boscia` together with the benchmarked problem, a comparison to the stored `master` branch values can be printed, showing whether the new benchmark is an `improvement`, `invariant` or a `regression` compared to the stored values.
Similarly, for `FrankWolfe` passing the computed benchmark to the function `compare_all_FW` together with the benchmarked `objective` and `LMO` displays the comparison for the stored values.

To compare against a single `problem` for a single `Frank-Wolfe` variant, the variant can be passed through the `fw` keyword.

### Example
First evaluate a new benchmark you wish to compare, e.g. `PCG` with `Birkhoff objective` on the `Birkhoff LMO`, and `Shortstep` as the `LineSearchMethod`.
```julia
new_bm = benchmark_FW(fw="PCG", obj="Birkhoff", lmo="Birkhoff", fw_kwargs=[(:line_search, FrankWolfe.Shortstep(2.0))])

# compare against stored values of PCG, Birkhoff obj and Birkhoff LMO
compare_all_FW(benchmark=new_bm, fw="PCG", obj="Birkhoff", lmo="Birkhoff")

# compare new benchmark against stored values of all FW variants for Birkhoff obj/LMO
compare_all_Boscia(benchmark=new_bm, obj="Birkhoff", lmo="Birkhoff")
```
