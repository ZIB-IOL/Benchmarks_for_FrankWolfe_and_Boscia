# Benchmarks for [FrankWolfe.jl](https://github.com/ZIB-IOL/FrankWolfe.jl) and [Boscia.jl](https://github.com/ZIB-IOL/Boscia.jl)
[Benchmarks_for_FrankWolfe_and_Boscia](https://github.com/ZIB-IOL/Benchmarks_for_FrankWolfe_and_Boscia) is a repository used to benchmark the [FrankWolfe.jl](https://github.com/ZIB-IOL/FrankWolfe.jl) and [Boscia.jl](https://github.com/ZIB-IOL/Boscia.jl) packages on select instances.

## Overview
The main way to benchmark either package is via [Weights & Biases (wandb)](https://wandb.ai/site/). To do this, a sweep needs to be configured and the necessary parameters need to be specified. The list of parameters is the same for both packages, but valid input may differ, e.g. problems which to benchmark. The table below gives an overview of which parameter inputs are allowed for the respective packages. An explanation for the `build_args` and `kwargs` paramters can be found under [Build and Keyword arguments](#build-arguments)
| Parameter | FrankWolfe | Boscia | 
| --------- | ---------- | ------ |
| package   | `FrankWolfe` | `Boscia` |
| fw_variant | `Vanilla`, `Lazy`, `Away`, `PCG`, `BCG`, `BPCG`, `DICG`, `BDICG` | `Vanilla`, `Away`, `BCG`, `BPCG` |
| build_args | `Dict(input)` | `Dict(input)` |
| seed | random seed: `Int` | random seed: `Int` |
| kwargs | `Dict(input)` | `Dict(input)`|
| time_per_run | time in secs: `Int` | time in secs: `Int` |
| num_runs | # of runs: `Int` | # of runs: `Int` | 

## Build and Keyword arguments
The easiest way to define the `build_args` and `kwargs` dictionary for benchmarking is to use [Julia](https://julialang.org) syntax. As an example, the `Birkhoff` problem for the `FrankWolfe` package takes the build parameters `n`, `active` and `seed`. A valid `build_args` dictionary could look as follows:
```
build_args = Dict(:n => 100, :active => true)
```
The `active` parameter is used solely for `Active Set` based methods and uses `ActiveSetProductCaching` instead of the default active set.

Most of the instances share some of the input parameters but there are slight differences, e.g., in contrast to `Birkhoff`, the `Simplex` problem takes `m` and `n` as dimension input, as well as `radius` for the `FrankWolfe.ProbabilitySimplexOracle`. A valid dictionary could look like
```
build_args = Dict(:m => 100, :n => 120, :radius => 1.0)
```
To see an overview of which problems take which arguments, see the tables in [FrankWolfe build args](#frankwolfe-build-args) and [Boscia build args](#boscia-build-args) respectively.

Across all problems, the separate `seed` parameter of the sweep controls the random seed used to build the instance. It does not need to be specified again in the `build_args`. Similarly, the `active` parameter defaults to `false`. Unless explicitly wanting to use `ActiveSetProductCaching`, not specifying the parameter uses the default active set for active set based algorithms. Hence, in the following we will only give an explanation of the other parameters.

### FrankWolfe build args

| Problem | Inputs | Explanation |
| --- | --- | --- |
| `Birkhoff`| `n`| `Dimension for (n, n) matrix`|
| `Nuclear` | `n`, `k`, `rhs`| `Dimension for (n, n) matrix`, `Rank of the matrix`, `Radius of LMO`|
| `A-Optimal`, `D-optimal`| `n`| `Dimension of matrix/Number of experiments`|
| `Poisson`| `n`| `Dimension of data`|
| `Simplex`| `m`, `n`, `radius` | `Number of rows in matrix`, `Number of cols in matrix`, `Radius of LMO`|
| `Sparse`| `n`, `K`, `rhs`| `Dimension of problem`, `Number of values in LMO`, `Radius of LMO`|
| `Spectrahedron`| `entries`, `n`, `radius`|`Number of known entries`, `Range of entry values and LMO dimension`, `Radius of LMO`|

All parameters have predefined default values, so it is not necessary to define all of them. It is however recommended to avoid unintended behaviour. Valid build dictionaries could look as follows:
```
# Birkhoff
Dict(:n => 100)

# Nuclear
Dict(:n => 50, :k => 15, :rhs => 200_000)

# A-Optimal, D-Optimal
Dict(:n => 250)

# Poisson
Dict(:n => 400)

# Simplex
Dict(:m => 5000, :n => 2500, :radius => 1.0)
Dict(:M => 5000, :n => 2500) # radius defaults to 1.0

# Sparse
Dict(:n => 10000, :K => 4000, :rhs => 1.0)

# Spectrahedron
Dict(:entries => 1000, :n => 500, :radius => 3.0)
```

### Boscia build args
| Problem | Inputs | Explanation |
| --- | --- | --- |
| `Birkhoff`| `n`, `k`| `Dimension for (n, n) matrix`, `Dimension of Simplex`|
| `CubeSimpleInt`, `CubeSimpleMix`| `n`| `Dimension of problem`|
| `LASSO`| `n`, `M_g`, `lambda_0_g`, `lambda_2_g`| `Determines group size and upper bound on number of nonzero variables`, `Bound on beta`, `Coefficient in objective`, `Coefficient in objective`|
| `Poisson`| `n`, `k`| `Dimension of problem`, `Upper bound on number of nonzero variables`|
| `Portfolio`| `n`| `Dimension of problem`|
| `SparseReg`| `n`| `Determines dimension of problem`|

Valid build dictionaries follow the same form as the ones for `FrankWolfe`.

### Keyword args
Similarly to the `build_args` parameter, the `kwargs` parameter takes a Julia dictionary as input. However, the keyword arguments for `FrankWolfe` and `Boscia` may differ. We refer to the respective documentations for [`FrankWolfe.jl`](https://zib-iol.github.io/FrankWolfe.jl/stable/) and [`Boscia.jl`](https://zib-iol.github.io/Boscia.jl/stable/). 

As an example, to use a different `LineSearchMethod` in `FrankWole` the parameter `line_search` can be passed as follows:
```
# Secant line search
kwargs = Dict(:line_search => FrankWolfe.Secant())

# Adaptive line search
kwargs = Dict(:line_search => FrankWolfe.Adaptive())
```

## Configuring a Sweep
When creating a sweep wandb asks for a configuration of the sweep. It is advised to configure this immediately. Alternatively, one can configure it by creating a `sweep.yaml` file. See the [wandb documentation](https://docs.wandb.ai/guides/sweeps/define-sweep-configuration/) for specifics.

In general, a sweep will take a couple of generic inputs, such as `program` or `method`. These should mostly be the same across all sweeps. `program` always refers to the file being run, here it is `wandb_interface.py`, and `method` controls how wandb combines the parameters. Usually, `grid` is advised as this method runs all combinations of parameters.

An example of a sweep configuration for `FrankWole` could look as follows:
```
program: wandb_interface.py

method: grid

parameters:
    package: 
        value: FrankWolfe

    fw_variant: 
        values: 
            - Vanilla
            - BCG
            - BPCG
        distribution: categorical
    
    problem:
        values:
            - Simplex
    
    build_args:
        values:
            - Dict(:m => 1000, :n => 800, :radius => 1.0)
            - Dict(:m => 1000, :n => 1200, :radius => 1.0)
        distribution: categorical
    
    seed:
        values: 
            - 1234
            - 5678
            - 123456789
        distribution: categorical
    
    kwargs: 
        values: [Dict(:line_search => FrankWolfe.Secant()), Dict(:line_search => FrankWolfe.Adaptive())]
    
    time_per_run:
        value: 3600
    
    num_runs:
        value: 10
```


