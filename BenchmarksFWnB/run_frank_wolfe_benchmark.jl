using BenchmarksFWnB

# read out parameters from slurm
variant = ARGS[1]
objective = ARGS[2]
lmo = ARGS[3]
set_up_idx = ARGS[4] # that depends on what that will be, if it is an integer it will be parse(Int64, ARGS[3])
branch_path = ARGS[5]

# run the benchmark
try
    benchmark_FW(; fw=variant, obj=objective, lmo=lmo, setup...)
    filename = variant * "_" * objective * "_" * lmo * "_"
catch e 
    println(e)
    file = "frank_wolfe_benchmark_" * variant * "_" * objective * "_" * lmo    
    open(file * ".txt","a") do io
        println(io, e)
    end
    display("$variant on $objective objective and $lmo LMO failed while running the benchmark. No benchmark will be saved!")
    display("Proceeding with the next iteration.")
    continue
end

# save the benchmark data
for mode in ["maximum", "mean", "median", "minimum"]
    filepath = joinpath(branch_path, filename * mode * ".json")
    save_benchmark(benchmark, mode=mode, filepath=filepath)
end

