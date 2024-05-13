"""
Compares benchmark 1 (bm1) against benchmark 2 (bm2) and decides whether bm1 is an improvement over bm2.

    # Arguments
    - 'bm1': evaluated benchmark to compare
    - 'bm2': evaluated benchmark against which to compare
    - 'mode': determines what to compare. Choose from "median", "mean", "minimum" or "maximum".
    - 'time_tolerance': percent tolerance on measured time up to which comparison is neutral
    - 'memory_tolerance': percent tolerance on memory consumption up to which comparison is neutral

    # Prints
    - decision whether bm1 is better than bm2 w.r.t. time and memory (including percent improvement)
"""
function compare_benchmarks(bm1, 
                            bm2; 
                            mode="median",
                            time_tolerance=0.05, 
                            memory_tolerance=0.01
                            )
    comp_1, comp_2 = @match mode begin
        "median"    => (median(bm1), median(bm2))
        "mean"      => (mean(bm1), mean(bm2))
        "minimum"   => (minimum(bm1), minimum(bm2))
        "maximum"   => (maximum(bm1), maximum(bm2))
        _           => (median(bm1), median(bm2))
    end

    println("Showing $mode comparison:\n")

    display(judge(comp_1, comp_2, time_tolerance=time_tolerance, memory_tolerance=memory_tolerance))
end;

"""
Saves median, mean or minimum of a benchmark to file.

# Arguments
- 'bm': evaluated benchmark run
- 'mode': "median", "mean", "minimum" or "maximum"
- 'filepath': path relative to current directory where to save output. Has to be .json file
"""
function save_benchmark(bm; 
                        mode="median", 
                        filepath="median.json"
                        )

    @match mode begin
        "median"    => BenchmarkTools.save("$filepath", median(bm))
        "mean"      => BenchmarkTools.save("$filepath", mean(bm))
        "minimum"   => BenchmarkTools.save("$filepath", minimum(bm))
        _           => BenchmarkTools.save("$filepath", median(bm))
    end
end