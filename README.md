# Benchmarks for [FrankWolfe.jl](https://github.com/ZIB-IOL/FrankWolfe.jl) v0.4.4

The benchmark results on this branch were obtained on version 0.4.4 of the FrankWolfe.jl package. 

## Benchmark setup
In total eight problems were benchmarked. The formulations of these problems can be found in the `BenchmarksFWnB/src/FrankWolfe` folder and the corresponding subfolder, e.g. `BenchmarksFWnB/src/FrankWolfe/birkhoff` for problem on the Birkhoff `LMO`. For further elaboration on the benchmarked problems, see Section 5 of the current [FrankWolfe.jl paper].

Each of the problems was paired with each of the available (and applicable) FrankWolfe variants, tested with 6 to 8 different setups and 5 different fixed seeds. Every combination of `FW variant`, `problem`, `setup` and `seed` was run 10 times and lastly we took the geometric mean of the results. Setups are stored in the `BenchmarksFWnB/src/FrankWolfe/setups_FW.jld2` file and can be loaded using the `JLD2` package.

The workflow for scheduling benchmarks can be found in the `BenchmarksFWnB/schedule_...` files. Results can be found in the `BenchmarksFWnB/results/master` folder and the files used for plots and tables can be found in the `BenchmarksFWnB/files_for_...` folders.

## Comments
- The `DICG` and `BDICG` variants are not applicable to all of the problems. Only _decomposition invariant_ `LMOs` are available for them and they consist of the `A` and `D Optimal Design` problems, as well as the `Birkhoff`, `Poisson` and `Simplex` problems.
- At the time of benchmarking, lazified versions of `DICG` and `BDICG` were not available.
- The `ActiveSetProductCaching` variants are only applicable to quadratic problems.


