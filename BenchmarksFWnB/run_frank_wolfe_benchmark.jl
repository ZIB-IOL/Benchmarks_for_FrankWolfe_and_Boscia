using BenchmarksFWnB
using Printf
using CSV
using DataFrames

# read out parameters from slurm
fw_variant = ARGS[1]
problem = ARGS[2]
setup_idx = ARGS[3]
branch_path = ARGS[4]

# run the benchmark
setup = read_setup_FW(problem=problem)[parse(Int64, setup_idx)]

try
    global bm, obj_counts, grad_counts, lmo_counts, dual_gaps, memory, times = benchmark_FW(; fw=fw_variant, problem=problem, setup...)
    global filename = fw_variant * "_" * problem * "_" * setup_idx * "_"
catch e 
    file = "frank_wolfe_benchmark_" * fw_variant * "_" * problem    
    open(file * ".txt","a") do io
        println(io, e)
    end
    display("$fw_variant on $problem problem failed while running the benchmark. No benchmark will be saved!")
    rethrow(e)  # Rethrow error to kill the process
end

# saving benchmark
isdir(branch_path) || mkpath(branch_path)
println("Benchmark run successful")
println()

println("Displaying results for $fw_variant Frank-Wolfe on $problem, setup $setup_idx")
println()
display(bm)
println()

println("Saving results...")

# save results for different modes
save_geomean(bm, joinpath(branch_path, filename * "geomean" * ".json"))

for mode in ["maximum", "mean", "median", "minimum"]
    try
        save_benchmark(bm; mode=mode, filepath=joinpath(branch_path, filename * mode * ".json"))
    catch e
        println("Saving data in mode $mode failed. Showing error.")
        show(e)
        continue
    end
end

# save misc values
header = [:dual_gaps, :LMO_calls, :grad_calls, :obj_calls, :memory, :times]
values = hcat(dual_gaps, lmo_counts, grad_counts, obj_counts, memory, times)
df = DataFrame(values, :auto)
rename!(df, header)
f = open(joinpath(branch_path, filename * "values.csv"), "a")
CSV.write(f, df, delim=',')
close(f)

println("Saving successful. Results are saved at $branch_path.")

