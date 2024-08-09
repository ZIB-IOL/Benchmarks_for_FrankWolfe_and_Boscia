using DataFrames, Latexify, CSV
header = ["(m x n)", "AFW", "BCG", "BPCG", "LFW", "PCG", "Vanilla"]
median_mat = convert(Matrix{Any}, zeros(8, 0))
for file in readdir()
    if endswith(file, "Simplex.csv")
        a = split(file, "_")[1]
        column = DataFrame(CSV.File(file))[!, "memory"]

        if length(column) < size(median_mat, 1)
            column = vcat(column, ["-" for _ in 1:(size(median_mat, 1)-length(column))])
        end

        global median_mat = hcat(median_mat, column)
    end
end
a = DataFrame(CSV.File("Lazy_Simplex.csv"))[!, "(m x n)"]
median_mat = hcat(a, median_mat)
df = DataFrame(median_mat, Symbol.(header))
latexify(df; env = :table, booktabs = true, latex = false) |> print