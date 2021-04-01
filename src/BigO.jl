module BigO

using BenchmarkTools
using RecipesBase
using Statistics
using Zygote: gradient

export RunReport
export bigos, guessbigo, best

include("run_report.jl")
include("order_estimation.jl")


end
