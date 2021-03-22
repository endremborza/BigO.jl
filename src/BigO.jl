module BigO

using BenchmarkTools
using DataFrames
using GLM
import Plots: plot

export RunReport, plot

"""
RunReport


"""
struct RunReport
    names::Array{String,1}
    inputsizes::Array{Int, 1}
    times::Array{Real,2}
    gctimes::Array{Real,2}
    allocs::Array{Int,2}
    allocsizes::Array{Int,2}
end


function RunReport(funcarray::Array, genfunc, insizes=10:10:100;
    seconds=1, samples=400)
    funnames = String.(Symbol.(funcarray))
    times = Array{Real,2}(undef, size(insizes,1), size(funnames,1))
    gctimes = times |> copy
    allocs = Array{Int, 2}(undef, size(times)...)
    allocsizes = allocs |> copy

    for (i, n) in enumerate(insizes)
        orig_in = genfunc(n)
        for (j, func) in enumerate(funcarray)
            trial = run(@benchmarkable $func(x) setup=(x=copy($orig_in)) seconds=seconds samples=samples)
            times[i, j] = median(trial.times)
            gctimes[i, j] = median(trial.gctimes)
            allocsizes[i, j] = trial.memory
            allocs[i, j] = trial.allocs
        end
    end
    RunReport(funnames, insizes, times, gctimes, allocs, allocsizes)
end

function RunReport(func, genfunc, insizes=10:10:100;
          seconds=1, samples=400)
    return RunReport([func], genfunc, insizes, seconds=seconds, samples=samples)
end

function plot(report::RunReport)
    labels = reshape(report.names, 1, size(report.names,1))
    ps = [
        plot(report.inputsizes, y, title=title) for (y, title) in
        zip([report.times, report.gctimes, report.allocs, report.allocsizes],
        ["Runtimes", "GC times", "Allocation counts", "Allocation sizes"])
    ]
    plot(ps..., layout = (2, 2), legend=:topleft, labels=labels, size=(800,600))
end

end
