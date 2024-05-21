using BenchmarksFWnB

# read out parameters from slurm
fw_variant = ARGS[1]
objective = ARGS[2]
lmo = ARGS[3]
setup_idx = ARGS[4]
branch_path = ARGS[5]

# run the benchmark
setup = read_setup_FW(objective=objective, lmo=lmo)[parse(Int64, setup_idx)]
try
    global bm = benchmark_FW(; fw=fw_variant, obj=objective, lmo=lmo, setup...)
    global filename = fw_variant * "_" * objective * "_" * lmo * "_" * setup_idx * "_"
catch e 
    file = "frank_wolfe_benchmark_" * fw_variant * "_" * objective * "_" * lmo    
    open(file * ".txt","a") do io
        println(io, e)
    end
    display("$fw_variant on $objective objective and $lmo LMO failed while running the benchmark. No benchmark will be saved!")
    rethrow(e)  # To kill the process we should rethrow the error. Printing would continue executing the file, trying to save the benchmark.
end

# saving benchmark
isdir(branch_path) || mkpath(branch_path)
println()
println("Benchmark run successful")
println()
sleep(1)
println("Displaying results for $fw_variant Frank-Wolfe on $lmo LMO with $objective objective, setup $setup_idx")
println()
display(bm)
println()
sleep(1)
println("Saving results...")
for mode in ["maximum", "mean", "median", "minimum"]
    try
        save_benchmark(bm; mode=mode, filepath=joinpath(branch_path, filename * mode * ".json"))
    catch e
        println("Saving data failed.")
        rethrow(e)
    end
end
sleep(1)
println("Saving successful. Results are saved at $branch_path.")

