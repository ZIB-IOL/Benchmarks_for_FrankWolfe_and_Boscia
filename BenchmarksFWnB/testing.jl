using CSV
using DataFrames
using LinearAlgebra
using BenchmarksFWnB

function read_columns_to_matrix(folder_path::String, prefix)
    # Initialize a list to store the results
    results = []

    # Get a list of all CSV files in the folder
    csv_files = filter(x -> startswith(x, prefix), readdir(folder_path))
    # display(csv_files)
    # return
    for file in csv_files
        file_joined = joinpath(folder_path, file)
        keep_first_11_lines(file_joined)
        # Read the CSV file into a DataFrame
        df = CSV.File(file_joined) |> DataFrame
        
        # Check if the specified columns exist in the DataFrame
        try
            # Extract the specified columns and convert to a matrix
            selected_data = df[!, :times]
            selected_data = BenchmarksFWnB.geom_shifted_mean(selected_data[:, 1], shift=1)
            push!(results, selected_data)
        catch
            println("Warning: Columns $(col1) or $(col2) not found in file $(file)")
        end
    end
    results = sort(results)
    # Concatenate all matrices vertically
    return vcat(results...)
end

function create_value_count_matrix(vector::Vector, threshold::Number)
    # Initialize a matrix to store the results
    result_matrix = zeros(Float64, length(vector), 2)

    # Iterate over the vector
    for i in 1:length(vector)
        # Store the original value in the first column
        result_matrix[i, 1] = vector[i]
        
        # Count how many entries up to the current index are smaller than the threshold
        count = sum(vector[j] < threshold for j in 1:i)
        
        # Store the count in the second column
        result_matrix[i, 2] = count
    end

    return result_matrix
end

function write_matrix_to_txt(matrix::Matrix, file_path::String)
    open(file_path, "w") do file
        for row in eachrow(matrix)
            # Join the elements of the row with a space and write to the file
            println(file, join(row, " "))
        end
    end
end

function keep_first_11_lines(file_path::String)
    # Read all lines from the file
    lines = readlines(file_path)

    # Extract the first 11 lines
    first_11_lines = lines[1:min(11, length(lines))]

    # Overwrite the file with the first 11 lines
    open(file_path, "w") do file
        for line in first_11_lines
            println(file, line)
        end
    end
end

path = joinpath(@__DIR__, "../results/FrankWolfe/master/")

fw_variants = [ "Vanilla",
                "Away",
                "Lazy",
                "BCG",
                "PCG",
                "BPCG",
                ]

problems    = [ "Simplex",
                "Birkhoff", 
                "Nuclear",  
                "Sparse",     
                "Spectrahedron", 
                "A-Criterion",  
                "D-Criterion",  
                "Poisson",   
              ] 

for variant in fw_variants
    for problem in problems
        prefix = variant * "_" * problem
        times = read_columns_to_matrix(path, prefix)
        value_count = create_value_count_matrix(times[:, 1], 3600)
        write_matrix_to_txt(value_count, joinpath(@__DIR__, "../results/FrankWolfe/master/", prefix * ".txt"))
    end
end
