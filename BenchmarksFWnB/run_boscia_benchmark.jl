using BenchmarksFWnB

# read out parameters from slurm
problem = ARGS[1]
fw_variant = ARGS[2]
setup_idx = ARGS[3]
branch_path = ARGS[4]

# run the benchmark
setup = read_setup_Boscia(problem=problem)[parse(Int64, setup_idx)]
try
    global bm = benchmark_Boscia(; fw=fw_variant, problem=problem, setup...)
    global filename = problem * "_" * fw_variant * "_" * setup_idx * "_"
catch e 
    println(e)
    file = "boscia_benchmark_" * problem * "_" * fw_variant    
    open(file * ".txt","a") do io
        println(io, e)
    end
    println("Run of $problem with $fw_variant failed. Process killed.")
    rethrow(e)
end

# saving benchmark
isdir(branch_path) || mkpath(branch_path)
println()
println("Benchmark run successful")
println()
sleep(1)
println("Displaying results for $problem solved with $fw_variant Frank-Wolfe, setup $setup_idx")
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

