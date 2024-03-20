""" 
Dummy example for showing how to compare FW benchmarks.

    - 'bm1' contains the evaluated benchmark run for default options (vanilla FW, simplex, random MSE)
    - 'bm2' contains the evaluated benchmark run for BPCG on simplex and random MSE objective

    Note that due to creating a new instance of MersenneTwister(seed) in each call the generated random data is indeed the same.
"""
include("BenchmarksFWnB/src/BenchmarksFWnB.jl")
using .BenchmarksFWnB

# vanilla fw
_, bm1 = benchmark_FW()

# blended pairwise 
_, bm2 = benchmark_FW(fw="BPCG")

# decides whether bm2 is an improvement over bm1 (or in general, if the benchmark in the first argument is better than the benchmark in the second argument)
compare_benchmarks(bm2, bm1)