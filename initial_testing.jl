""" 
Dummy file for running benchmarks from command line.

Running this file via 'include("initial_testing.jl") from the REPL works as intended.
Currently, there is only one setup for Frank-Wolfe and Boscia, respectively, to showcase the functionality. 
These setups will likely change over time so be wary of longer runtimes, etc.

The way 'run(...)' is presented here is how it will be called by the .sh script when calling the functions 'run_all_FW' and 'run_all_Boscia', respectively.
"""
branch_path = joinpath(@__DIR__, "results/Boscia/Dummy")
variant = "Away"
problem = "CubeSimpleInt"
setup_idx = 1

# updates/creates Manifest.toml for the project locally
run(`julia --project=BenchmarksFWnB -e 'using Pkg; Pkg.update()'`)
println("Updated Manifest.toml. Proceeding with Boscia example.\n")
run(`julia --project=BenchmarksFWnB BenchmarksFWnB/run_boscia_benchmark.jl $problem $variant $setup_idx $branch_path`)

println("Proceeding with Frank-Wolfe example.")

branch_path = joinpath(@__DIR__, "results/FrankWolfe/Dummy")
objective = "MSE"
lmo = "Simplex"
variant = "Lazy"
run(`julia --project=BenchmarksFWnB BenchmarksFWnB/run_frank_wolfe_benchmark.jl $variant $objective $lmo $setup_idx $branch_path`)
