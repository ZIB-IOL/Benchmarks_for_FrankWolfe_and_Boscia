""" 
Dummy example for showing how to compare benchmarks.

    # FrankWolfe
    - 'bm1' is default options (vanilla, simplex, random MSE), bm2 uses BPCG instead.
    - Should show big improvement

    # Boscia
    - 'bm1' is default options (BPCG, cube simple int), bm2 uses vanilla instead.
"""

using BenchmarksFWnB

# vanilla fw
bm1 = benchmark_FW(lmo_n=20, obj_n=100, obj_k=20, seconds=60)

# blended pairwise 
bm2 = benchmark_FW(fw="BPCG", lmo_n=20, obj_n=100, obj_k=20, seconds=60)

# decides whether bm2 is an improvement over bm1 (or in general, if the benchmark in the first argument is better than the benchmark in the second argument)
println("Frank-Wolfe \nBPCG vs. Vanilla \n")
compare_benchmarks(bm2, bm1)

println()

bm1 = benchmark_Boscia(n=10, seconds=60)
bm2 = benchmark_Boscia(fw="vanilla", n=10, seconds=60)

println("Boscia \nVanilla vs. BPCG \n")
compare_benchmarks(bm2, bm1)
