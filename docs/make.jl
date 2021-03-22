using BigO
using Documenter

DocMeta.setdocmeta!(BigO, :DocTestSetup, :(using BigO); recursive=true)

makedocs(;
    modules=[BigO],
    authors="Endre Márk Borza",
    repo="https://github.com/endremborza/BigO.jl/blob/{commit}{path}#{line}",
    sitename="BigO.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://endremborza.github.io/BigO.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/endremborza/BigO.jl",
)
