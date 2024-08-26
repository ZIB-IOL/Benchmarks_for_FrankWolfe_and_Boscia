# Benchmarks_for_FrankWolfe_and_Boscia
Benchmarks for the FrankWolfe.jl and Boscia.jl packages

## Quick guide
The main functions to benchmark a given branch, `run_all_FW()` and `run_all_Boscia()`, are contained in `run_all_benchmarks.jl` in the folder where the source folder `src` is located. They are used to benchmark all the Frank-Wolfe variants on all the problems available in this repository. To use them, open this Julia project through the command line with `julia --project` and then load the functions with `include("run_all_benchmarks.jl")`. To benchmark a specific branch, e.g. master branch for `FrankWolfe.jl`, execute `run_all_FW(branch="master")`. 

## Benchmark setups
Setups for the problems are stored in `src/FrankWolfe/setups_FW.jld2` and `src/Boscia/setups_Boscia.jld2`, respectively. 