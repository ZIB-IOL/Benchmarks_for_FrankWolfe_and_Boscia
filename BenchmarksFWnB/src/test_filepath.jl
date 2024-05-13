include("BenchmarksFWnB.jl")
using .BenchmarksFWnB

bm = benchmark_Boscia(seconds=20)

for mode in ["maximum", "mean", "median", "minimum"]
    save_benchmark(bm, mode=mode, filepath="$mode.json")
end

