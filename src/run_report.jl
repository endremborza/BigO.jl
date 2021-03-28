const DEFAULT_INPUTS = 20:20:240
const DEFAULT_SECONDS = 1
const DEFAULT_SAMPLES = 200


struct RunReport
    names::Array{String,1}
    inputsizes::Array{Int, 1}
    times::Array{Real,2}
    gctimes::Array{Real,2}
    allocs::Array{Int,2}
    allocsizes::Array{Int,2}
end

"""
    RunReport(args...; kwargs...) -> Manager

Creates profiles for functions of runtime and memory consumption for different input sizes.

# Arguments

- `funcarray::Array{Base.Callable}` or `func::Base.Callable`: the function(s) to profile
- `genfunc::Base.Callable`: function that generates inputs of different sizes for
the function(s)
- `insizes`: iterable of integers that are used as inputs for `genfunc`

# Keywords

- `seconds::Number`: parameter of `@benchmarkable`
- `samples::Integer`: parameter of `@benchmarkable`
"""
function RunReport(
    funcarray::Array,
    genfunc::Base.Callable,
    insizes=DEFAULT_INPUTS;
    seconds=DEFAULT_SAMPLES,
    samples=DEFAULT_SAMPLES
    )
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

function RunReport(
    func,
    genfunc::Base.Callable,
    insizes=DEFAULT_INPUTS;
    seconds=DEFAULT_SECONDS,
    samples=DEFAULT_SAMPLES)
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
