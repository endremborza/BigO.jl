using BigO
using Test
using Random
using  RecipesBase


@testset "BigO.jl" begin

    Random.seed!(42069);

    report = RunReport([sort, sort!], rand, 10:10:50, samples=3)
    @test report.names == ["sort", "sort!"]
    rec = RecipesBase.apply_recipe(Dict{Symbol, Any}(), report)
    @test rec[1].plotattributes[:title] == "Runtimes"
    @test rec[1].plotattributes[:label] == ["sort" "sort!"]


    report1 = RunReport(sort, rand, 10:10:50, samples=3)
    @test report1.names == ["sort"]

    @test typeof(bigos(report)) == Dict{String, String}

    testfuns = [
        (x -> 0.3 + 0.7 * x + rand() / 5, "O(n)"),
        (x -> 7 + 2 * log(x) + rand() / 10, "O(log n)"),
        (x -> 27 + 13 * x ^ 1.7 + rand(), "O(n^p)"),
        (x -> 1000 + 5 * x + 1.8 ^ x + rand(), "O(k^n)"),
        (x -> 100 + 2.5 * x * log(5, x) + rand() / 3, "O(n log n)"),

    ]

    for (truf, name) in testfuns
        x = 50:20:400;
        y = truf.(x);
        guess = guessbigo(x, y)
        @test guess[1].name == name
    end

    @test (guessbigo(x -> 10) |> best) == "O(1)"

end
