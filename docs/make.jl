using Documenter, Tracy

DocMeta.setdocmeta!(Tracy, :DocTestSetup, :(using Tracy); recursive=true)
makedocs(modules = [Tracy], sitename="Tracy.jl")

deploydocs(repo = "github.com/topolarity/Tracy.jl.git")
