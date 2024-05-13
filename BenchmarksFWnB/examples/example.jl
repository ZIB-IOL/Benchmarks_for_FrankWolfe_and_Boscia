""" 
Dummy example for showing how to compare benchmarks
"""

using BenchmarksFWnB

# vanilla fw
bm1 = benchmark_FW(lmo_args=[(:n, 20)], obj_args=[(:n, 100), (:k, 20)], seconds=60)

# blended pairwise 
bm2 = benchmark_FW(fw="BPCG", lmo_args=[(:n, 20)], obj_args=[(:n, 100), (:k, 20)], seconds=60)

# decides whether bm2 is an improvement over bm1 (or in general, if the benchmark in the first argument is better than the benchmark in the second argument)
println("Frank-Wolfe \nBPCG vs. Vanilla \n")
compare_benchmarks(bm2, bm1)


# save median benchmark values
save_benchmark(bm1, mode="median", filepath="example_vanilla.json")
save_benchmark(bm2, mode="median", filepath="example_BPCG.json")

# read in benchmark values for comparison
read_bm1 = BenchmarkTools.read("example_vanilla.json")
read_bm2 = BenchmarkTools.read("example_BPCG.json")

println("Saved vs. computed: \n")
compare_benchmarks(read_bm1, bm1)
compare_benchmarks(read_bm2, bm2)



