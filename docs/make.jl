using Documenter
using LogNormals
using Distributions, StatsBase, StatsPlots, Missings, MissingStrategies

push!(LOAD_PATH,"../src/")
# need to add Statistics and Distributions to Project.toml in docs/
#DocMeta.setdocmeta!(LogNormals, :DocTestSetup, :(using Statistics,Distributions,LogNormals); recursive=true)
#DocMeta.setdocmeta!(Distributions, :DocTestSetup, :(using Statistics,Distributions,LogNormals); recursive=true)
makedocs(sitename="LogNormals.jl",
         doctest=false,
         pages = [
            "Home" => "index.md",
            "LogNormal properties" => "lognormalprops.md",
            "Fit to statistic" => "fitstats.md",
            "sem correlated" => "semcor.md",
         ],
         modules = [LogNormals],
         format = Documenter.HTML(prettyurls = false)
)
# Documenter can also automatically deploy documentation to gh-pages.
# See "Hosting Documentation" and deploydocs() in the Documenter manual
# for more information.
deploydocs(
    repo = "github.com/bgctw/LogNormals.jl.git",
    devbranch = "main"
)
