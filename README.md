# Tracy.jl


[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://topolarity.github.io/Tracy.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://topolarity.github.io/Tracy.jl/dev)

A flexible profiling tool for tracing Julia code, LLVM compilation, Garbage Collection, and more.

# Tracing Julia code

Code you'd like to trace should be wrapped with `@tracepoint`

```julia
@tracepoint "name" <expression>
```

Typically the expression will be a `begin-end` block:

```julia
@tracepoint "data aggregation" begin
    # lots of compute here...
end
```
