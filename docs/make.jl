using Documenter, Tracy, TracyProfiler_jll

DocMeta.setdocmeta!(Tracy, :DocTestSetup, :(using Tracy, TracyProfiler_jll); recursive=true)
makedocs(modules = [Tracy], sitename="Tracy.jl")

deploydocs(repo = "github.com/topolarity/Tracy.jl.git")
