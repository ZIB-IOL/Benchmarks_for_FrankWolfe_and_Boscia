# Explanation
You will additionally need the `Match` package, which allows switch-cases in a prettier manner than constantly doing `if-else`.

Navigate into `BenchmarksFWnB/src` folder in the Julia shell (or whichever way, Julia should be run there), so you are in the same directory as `Boscia, FrankWolfe, BenchmarksFWnB.jl`. There, do `include("BenchmarksFWnB.jl")`. This will include the module and export the `create_data_FW` function which gets the data for Frank-Wolfe based functions. From here write:
```julia
fw, f, grad!, lmo, x0 = create_data_FW("vanilla", "ProbSimplex", "random matrix sq norm", 10);

fw(f, grad!, lmo, x0)
```
This should run the vanilla Frank-Wolfe with `f, grad!, lmo, x0` as intended and return some sensible output.

`random matrix sq norm` is a terrible name, I know. For now it's only for testing, let's discuss naming after vacation.