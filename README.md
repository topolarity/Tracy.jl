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

#### Preferences support

Tracepoints can be toggled or filtered module-wide with a `LocalPreferences.toml` file:

```toml
[MyPackage.Tracy]
enabled = true
whitelist = ['foo', 'bar.*']
blacklist = ['baz']
```

Put the "LocalPreferences.toml" alongside the "Project.toml" for the currently active project/environment, and the rest is taken care of automatically.

Alternatively, you can use the Preferences API to update the LocalPreferences.toml for you:
```julia
julia> set_preferences!(MyPackage, "Tracy" => Dict("enabled" => true, "whitelist" => ["foo", "bar.*"]))
```

To publish default preferences for your package, simply copy the "LocalPreferences.toml" file to a "Preferences.toml" file next to the Project.toml for your package. Users of your package will have these preferences applied by default, and these published settings can always be overridden by a top-level "LocalPreferences.toml".
