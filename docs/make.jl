using Documenter, Tracy

makedocs(modules = [Tracy], sitename="Tracy.jl")

deploydocs(repo = "github.com/topolarity/Tracy.jl.git")
