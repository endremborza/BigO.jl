module BigO

using BenchmarkTools
using Statistics
using Zygote: gradient

import Plots: plot

export RunReport, plot
export bigos, guessbigo, best

include("run_report.jl")
include("order_estimation.jl")


end
