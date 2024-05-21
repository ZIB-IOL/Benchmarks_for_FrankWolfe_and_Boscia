using BenchmarksFWnB

# read out parameters from slurm
problem = ARGS[1]
variant = ARGS[2]
set_up_idx = ARGS[3] # that depends on what that will be, if it is an integer it will be parse(Int64, ARGS[3])
branch_path = ARGS[4]

# run the benchmark
try
    benchmark = benchmark_Boscia(; fw=variant, problem=problem, setup...)
    filename = problem * "_" * variant * "_"
catch e 
    println(e)
    file = "boscia_benchmark_" * problem * "_" * variant    
    open(file * ".txt","a") do io
        println(io, e)
    end
    display("$variant on $problem failed while running the benchmark. No benchmark will be saved!")
    display("Proceeding with the next iteration.")
end

# save the benchmark data
for mode in ["maximum", "mean", "median", "minimum"]
    filepath = joinpath(branch_path, filename * mode * ".json")
    save_benchmark(benchmark, mode=mode, filepath=filepath)
end

