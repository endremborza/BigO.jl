using BigO
using Test

@testset "BigO.jl" begin
    report = RunReport([sort, sort!], rand, 10:10:50, samples=3)
    @test report.names == ["sort", "sort!"]
    report |> plot

    report1 = RunReport(sort, rand, 10:10:50, samples=3)
    @test report1.names == ["sort"]
end
