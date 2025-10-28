using DataFrames
using CSV
using Plots

function plot_subplots_save(x1, y1, x2, y2; label1="Line 1", title="Plot 1", x1label="", y1label="", x2label="", y2label="")
    # Create a 2x2 grid of subplots
    #x1scale = x1[end] > 1000 && x3[end] > 1000 ? :log10 : :identity
    x1scale = :identity
    #x2scale = x2[end] > 300 && x4[end] > 300 ? :log10 : :identity
    x2scale = :identity
    p1 = plot(x1, y1, label=label1, ylabel=y1label, xscale=x1scale) #xscale=:log10
    # plot!(x3, y3, label=label2, color=:red)  # Adding second line to the first subplot

    p2 = plot(x2, y1, label=label1, xscale=x2scale)
    # plot!(x4, y3, label=label2, color=:red)  # Adding second line to the second subplot

    p3 = plot(x1, y2, label=label1, xlabel=x1label, ylabel=y2label, xscale=x1scale)
    # plot!(x3, y4, label=label2, color=:red)  # Adding second line to the third subplot

    p4 = plot(x2, y2, label=label1, xlabel=x2label, xscale=x2scale)
    # plot!(x4, y4, label=label2, color=:red)  # Adding second line to the fourth subplot

    # Combine the plots into one figure with a 2x2 layout
    # Add explicit size and margins to prevent cropping
    combined_plot = plot(p1, p2, p3, p4, layout=(2, 2), size=(2560, 1440), margin=10Plots.mm, left_margin=15Plots.mm)

    # Save the plot to a file
    filename = joinpath(@__DIR__, "figures/" * title * ".png")
    savefig(filename)
end

function export_data(
    data,
    labels;
    filename_prefix="Boscia",
    filename_suffix="",
    iter_skip=1,
    compute_FWgaps=true,
)
    file_name = joinpath(@__DIR__, "data/" * filename_prefix * "_" * filename_suffix * ".txt")
    open(file_name, "w") do io 
        println(io, join(labels, " "))
        stop = length(data) >= 2000 ? 2000 : length(data)
        for i in range(1,step=iter_skip,stop=stop)
            println(io, join(data[i], " "))
        end
    end
end

function extract_data(filename; dim=0, seed=0)
    data = []
    df = DataFrame(CSV.File(filename))
    df[1,:time] = 0.0001
    length = nrow(df)
    indices =  if length > 2000 
        vcat(collect(1:999), Int.(round.(collect(1000:(length-1000)/1000:(length-1000))))) 
    else
         Int.(collect(1:length))
    end
    for row in eachrow(df)
        if rownumber(row) in indices
            push!(data, collect(row))
        end
    end
    return data
end