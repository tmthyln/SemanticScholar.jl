push!(LOAD_PATH, "../src/")

using Documenter, SemanticScholar

makedocs(
    sitename="SemanticScholar.jl Documentation",
    format=Documenter.HTML(
        prettyurls=get(ENV, "CI", nothing) == "true"
    ),
    modules=[SemanticScholar],
    pages=[
        "Home" => "index.md",
        "API Reference" => [
            "Low-Level API" => "api_low_level.md",
            "High-Level API" => "api_high_level.md",
        ],
    ],
)

deploydocs(
    repo = "github.com/tmthyln/SemanticScholar.jl.git",
    devbranch = "main",
    devurl="latest",
)
