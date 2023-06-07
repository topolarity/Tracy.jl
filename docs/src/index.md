# Tracy.jl

A flexible profiling tool for tracing Julia code, LLVM compilation, Garbage Collection, and more.

```@docs
@tracepoint
tracymsg
Tracy.@register_tracepoints
Tracy.enable_tracepoint
Tracy.wait_for_tracy
Tracy.capture
```

#### Preferences support

Tracepoints can be toggled or filtered module-wide with a `LocalPreferences.toml` file:

```toml
[MyPackage.Tracy]
enabled = true
whitelist = ['foo', 'bar.*']
blacklist = ['baz']
```

Put the `LocalPreferences.toml` alongside the `Project.toml` for the currently active project (use `julia --project=...` to set the active project), and the rest is taken care of automatically.

To publish default preferences for your package, simply copy the "LocalPreferences.toml" file to a `Preferences.toml` file next to the Project.toml for your package. Users of your package will have these preferences applied by default, and any published settings can always be overridden by a top-level `LocalPreferences.toml`.
