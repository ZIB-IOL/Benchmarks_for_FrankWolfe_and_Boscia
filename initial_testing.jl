## File for initial testing
using BenchmarksFWnB

fw, f, grad!, lmo, x0 = create_data_FW("vanilla", "ProbSimplex", "random matrix sq norm", 10);

bench = fw(f, grad!, lmo, x0)

@show bench
