# using JLD2
# using CSV
# using DataFrames
# using Printf

# write_folder = "/home/htc/dkuzinow/research_projects/Benchmarks_for_FrankWolfe_and_Boscia/files_for_tables"
# read_folder = "/home/htc/dkuzinow/research_projects/Benchmarks_for_FrankWolfe_and_Boscia/BenchmarksFWnB/benchmark_output/"
# values_folder = "/home/htc/dkuzinow/research_projects/Benchmarks_for_FrankWolfe_and_Boscia/results/FrankWolfe/master/"

# normal_vars = ["Vanilla", "Away", "PCG", "BCG", "BPCG"]
# normal_problems = ["Birkhoff", "Nuclear", "A-Criterion", "D-Criterion", "Poisson", "Simplex", "Sparse", "Spectrahedron"]

# dicg_vars = ["DICG", "BDICG"]
# dicg_problems = [
#                     "Simplex", 
#                     "Birkhoff",
#                     "A-Criterion", 
#                     "D-Criterion", 
#                     "Poisson", 
#                 ]

# lazy_vars = ["Lazy", "Away", "PCG", "BCG", "BPCG"]
# act_vars = ["Away", "PCG", "BCG", "BPCG"]
# act_problems = ["Simplex", "Birkhoff", "Nuclear", "Sparse", "Spectrahedron"]

# seeds       = [ 6237259982982784263,
#                   4029983743574629836,
#                   8775360557774874450,
#                   3837242124960531782,
#                   2604058079039351027,
#                 ]

# function geom_shifted_mean(xs; shift=big"0.0")
#   n = length(xs)
#   r = prod(xi + shift for xi in xs)
#   return Float64(r^(1/n) - shift)
# end

# # # BASE AND DICG VARIANTS
# # for problem in normal_problems
# #   # DICG PROBLEMS
# #   if problem in dicg_problems
# #     variants = vcat(normal_vars, dicg_vars)
# #   else
# #     variants = normal_vars
# #   end

# #   setups = load("src/FrankWolfe/setups_FW.jld2", problem)
# #   dims = []

# #   f = open("$(write_folder)/$(problem)_table.txt", "w")
# #   for i in eachindex(setups)

# #     write_line = ""
# #     times = []
# #     mems = []
# #     dual_gaps = []

# #     setup = setups[i]
# #     dim = setup[1][2][1][2]
# #     if problem == "Simplex"
# #       dim = (dim, setup[1][2][2][2])
# #     end
# #     if problem == "Spectrahedron"
# #       dim = setup[1][2][2][2]
# #     end
# #     if problem in ["Nuclear", "Birkhoff", "Spectrahedron"]
# #       dim = dim * dim
# #     end
# #     if problem == "Simplex"
# #       write_line *= "$(dim[1]), $(dim[2]) & "
# #     else
# #       write_line *= "$(dim) & "
# #     end
    
# #     for variant in variants
# #       # TIME AND DUAL GAPS 
# #       i_times = []
# #       i_duals = []
# #       i_mems = []
# #       for seed in seeds 
# #         if problem == "Birkhoff" && variant == "BCG" && seed == 3837242124960531782
# #           continue
# #         end
# #         try
# #           global df = CSV.read("$(values_folder)/$(variant)_$(problem)_$(i)_$(seed).csv", DataFrame)
# #         catch
# #           global df = CSV.read("$(values_folder)/$(variant)_$(problem)_$(i)_$(seed)_values.csv", DataFrame)
# #         end
# #         try
# #           global ts = df[!, "times"]
# #         catch
# #           global ts = df[!, " times"]
# #         end
# #         ds = df[!, "dual_gaps"]
# #         ds = convert(Vector{BigFloat}, ds)
# #         for j in eachindex(ds)
# #           ts[j] = min(ts[j], 3600.0)
# #           ds[j] = max(ds[j], 1e-7)
# #         end
# #         append!(i_times, ts)
# #         append!(i_duals, ds)

# #         # READ MEMORY AND CONVERT TO GB
# #         line = readlines("$(read_folder)/frank_wolfe_benchmark_$(variant)_$(problem)_$(i)_$(seed).log")[end-3][19:end]
# #         line = split(line, " ")
# #         mem = parse(Float64, line[1])
# #         mode = line[2]
# #         if mode == "GiB,"
# #           mem = 1.073741824 * mem
# #         elseif mode == "MiB,"
# #           mem = 0.001048576 * mem
# #         elseif mode == "KiB,"
# #           mem = 1.024e-6 * mem
# #         end
# #         push!(i_mems, mem)
# #       end

# #       geom_time = geom_shifted_mean(i_times; shift=1)
# #       geom_dual = geom_shifted_mean(i_duals; shift=1)
# #       geom_mem = geom_shifted_mean(i_mems; shift=1)

# #       geom_time = @sprintf("%.2e", geom_time)
# #       geom_mem = @sprintf("%.2e", geom_mem)
# #       geom_dual = @sprintf("%.2e", geom_dual)

# #       write_line *= "$(geom_time) & "
# #       write_line *= "$(geom_mem) & "
# #       write_line *= "$(geom_dual) & "
# #     end  
# #     write_line = write_line[1:end-2]
# #     write_line *= "\\\\ \n"
# #     write(f, write_line)
# #   end
# #   close(f)
# # end


# # # LAZY VARIANTS
# # for problem in normal_problems
# #   variants = lazy_vars
# #   setups = load("src/FrankWolfe/setups_FW.jld2", problem)
# #   dims = []

# #   f = open("$(write_folder)/Lazy_$(problem)_table.txt", "w")
# #   for i in eachindex(setups)

# #     write_line = "& "
# #     times = []
# #     mems = []
# #     dual_gaps = []

# #     setup = setups[i]
# #     dim = setup[1][2][1][2]
# #     if problem == "Simplex"
# #       dim = (dim, setup[1][2][2][2])
# #     end
# #     if problem == "Spectrahedron"
# #       dim = setup[1][2][2][2]
# #     end
# #     if problem in ["Nuclear", "Birkhoff", "Spectrahedron"]
# #       dim = dim * dim
# #     end
# #     if problem == "Simplex"
# #       write_line *= "$(dim[1]), $(dim[2]) & "
# #     else
# #       write_line *= "$(dim) & "
# #     end
    
# #     for variant in variants
# #       # TIME AND DUAL GAPS 
# #       i_times = []
# #       i_duals = []
# #       i_mems = []
# #       for seed in seeds 
# #         if problem == "Birkhoff" && variant == "BCG" && seed == 3837242124960531782
# #           continue
# #         end
# #         try
# #           global df = CSV.read("$(values_folder)/$(variant)_$(problem)_$(i)_$(seed).csv", DataFrame)
# #         catch
# #           global df = CSV.read("$(values_folder)/$(variant)_$(problem)_$(i)_$(seed)_values.csv", DataFrame)
# #         end
# #         try
# #           global ts = df[!, "times"]
# #         catch
# #           global ts = df[!, " times"]
# #         end
# #         ds = df[!, "dual_gaps"]
# #         ds = convert(Vector{BigFloat}, ds)
# #         for j in eachindex(ds)
# #           ts[j] = min(ts[j], 3600.0)
# #           ds[j] = max(ds[j], 1e-7)
# #         end
# #         append!(i_times, ts)
# #         append!(i_duals, ds)

# #         # READ MEMORY AND CONVERT TO GB
# #         if variant != "Lazy"
# #           line = readlines("$(read_folder)/frank_wolfe_benchmark_Lazy$(variant)_$(problem)_$(i)_$(seed).log")[end-3][19:end]
# #         else
# #           line = readlines("$(read_folder)/frank_wolfe_benchmark_$(variant)_$(problem)_$(i)_$(seed).log")[end-3][19:end]
# #         end
# #         line = split(line, " ")
# #         mem = parse(Float64, line[1])
# #         mode = line[2]
# #         if mode == "GiB,"
# #           mem = 1.073741824 * mem
# #         elseif mode == "MiB,"
# #           mem = 0.001048576 * mem
# #         elseif mode == "KiB,"
# #           mem = 1.024e-6 * mem
# #         end
# #         push!(i_mems, mem)
# #       end

# #       geom_time = geom_shifted_mean(i_times; shift=1)
# #       geom_dual = geom_shifted_mean(i_duals; shift=1)
# #       geom_mem = geom_shifted_mean(i_mems; shift=1)

# #       geom_time = @sprintf("%.2e", geom_time)
# #       geom_mem = @sprintf("%.2e", geom_mem)
# #       geom_dual = @sprintf("%.2e", geom_dual)

# #       write_line *= "$(geom_time) & "
# #       write_line *= "$(geom_mem) & "
# #       write_line *= "$(geom_dual) & "
# #     end  
# #     write_line = write_line[1:end-2]
# #     write_line *= "\\\\ \n"
# #     write(f, write_line)
# #   end
# #   close(f)
# # end

# output_files = readdir(read_folder)

# # ACTIVE SET PRODUCT CACHING
# for problem in act_problems
#   variants = act_vars
#   setups = load("src/FrankWolfe/setups_FW.jld2", problem)
#   dims = []

#   f = open("$(write_folder)/ProductCaching_$(problem)_table.txt", "w")
#   for i in eachindex(setups)

#     write_line = "& "
#     times = []
#     mems = []
#     dual_gaps = []

#     setup = setups[i]
#     dim = setup[1][2][1][2]
#     if problem == "Simplex"
#       dim = (dim, setup[1][2][2][2])
#     end
#     if problem == "Spectrahedron"
#       dim = setup[1][2][2][2]
#     end
#     if problem in ["Nuclear", "Birkhoff", "Spectrahedron"]
#       dim = dim * dim
#     end
#     if problem == "Simplex"
#       write_line *= "$(dim[1]), $(dim[2]) & "
#     else
#       write_line *= "$(dim) & "
#     end
    
#     for variant in variants
#       # TIME AND DUAL GAPS 
#       i_times = []
#       i_duals = []
#       i_mems = []
#       for seed in seeds 
#         if problem == "Birkhoff" && variant == "BCG" && seed == 3837242124960531782
#           continue
#         end
#         try
#           global df = CSV.read("$(values_folder)/$(variant)_ActiveSetQuadratic_$(problem)_$(i)_$(seed).csv", DataFrame)
#         catch
#           global df = CSV.read("$(values_folder)/$(variant)_ActiveSetQuadratic_$(problem)_$(i)_$(seed)_values.csv", DataFrame)
#         end
#         try
#           global ts = df[!, "times"]
#         catch
#           global ts = df[!, " times"]
#         end
#         ds = df[!, "dual_gaps"]
#         ds = convert(Vector{BigFloat}, ds)
#         for j in eachindex(ds)
#           ts[j] = min(ts[j], 3600.0)
#           ds[j] = max(ds[j], 1e-7)
#         end
#         append!(i_times, ts)
#         append!(i_duals, ds)

#         # READ MEMORY AND CONVERT TO GB
#         id = findfirst(x -> startswith(x, "frank_wolfe_benchmark_ActiveSetQuadratic_$(variant)_$(problem)_$(i)_$(seed)"), output_files)
#         file = output_files[id]
#         line = readlines("$(read_folder)/$(file)")[end-3][19:end]
#         line = split(line, " ")
#         mem = parse(Float64, line[1])
#         mode = line[2]
#         if mode == "GiB,"
#           mem = 1.073741824 * mem
#         elseif mode == "MiB,"
#           mem = 0.001048576 * mem
#         elseif mode == "KiB,"
#           mem = 1.024e-6 * mem
#         end
#         push!(i_mems, mem)
#       end

#       geom_time = geom_shifted_mean(i_times; shift=1)
#       geom_dual = geom_shifted_mean(i_duals; shift=1)
#       geom_mem = geom_shifted_mean(i_mems; shift=1)

#       geom_time = @sprintf("%.2e", geom_time)
#       geom_mem = @sprintf("%.2e", geom_mem)
#       geom_dual = @sprintf("%.2e", geom_dual)

#       write_line *= "$(geom_time) & "
#       write_line *= "$(geom_mem) & "
#       write_line *= "$(geom_dual) & "
#     end  
#     write_line = write_line[1:end-2]
#     write_line *= "\\\\ \n"
#     write(f, write_line)
#   end
#   close(f)
# end
read_folder = "/home/htc/dkuzinow/research_projects/Benchmarks_for_FrankWolfe_and_Boscia/results/FrankWolfe/master/"

for file in readdir(read_folder)
    if endswith(file, ".csv")
        lines = readlines(joinpath(read_folder, file))
        if lines[1] == "dual_gaps, times"
            lines[1] = "dual_gaps,times"
            write(joinpath(read_folder, file), join(lines, "\n"))
        end
    end
end
