push!(LOAD_PATH, "../src/")

using Documenter, <module-name>

makedocs(
    sitename="<package-name> Documentation",
    format=Documenter.HTML(
        prettyurls=get(ENV, "CI", nothing) == "true"
    ),
    modules=[<module-name>],
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(
    repo = "github.com/tmthyln/<package-name>.git",
    devbranch = "main",
    devurl="latest",
)
