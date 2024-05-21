""" 
WILL UPDATE ACCORDINGLY ONCE EVERYTHING IS PROPERLY SET UP.

Dummy example for how to use the benchmark package. 

To run this file, navigate to the directory where 'BenchmarksFWnB.jl' is contained (in the folder 'BenchmarksFWnB') and 
then execute the command 'julia --project=. ../initial_testing.jl'. This will activate the 'BenchmarksFWnB' project with all
necessary dependencies and afterwards run the 'initial_testing.jl' file.

'display(bm1)' prints the evaluated benchmark run to the console -> good for saving to SCRATCH on z1
"""

using BenchmarksFWnB

# for demonstration we limit the runtime to 10 seconds
bm1 = benchmark_FW(fw="Vanilla", obj_args=[(:n, 100), (:k, 30)], lmo_args=[(:n, 30)], seconds=10)

# displays benchmark graphic
display("Benchmark for ")
display(bm1)

# compare vanilla against pairwise FW
bm2 = benchmark_FW(fw="PCG", obj_args=[(:n, 100), (:k, 30)], lmo_args=[(:n, 30)], seconds=10)

display(bm2)

# shows 'judge' comparison between 'bm1' and 'bm2' w.r.t. the mean values of 'time' and 'memory'
compare_benchmarks(bm1, bm2, mode="mean")

# Similarly for Boscia
bm1 = benchmark_Boscia(problem="CubeSimpleInt", seconds=30)

display(bm1)

# default for Boscia is BPCG, so compare against vanilla
bm2 = benchmark_Boscia(fw="Vanilla", problem="CubeSimpleInt", seconds=30)

display(bm2)

compare_benchmarks(bm1, bm2)
