# This file is a part of Tracy.jl. License is MIT: See LICENSE.md

_is_func_def(ex) = Meta.isexpr(ex, :function) || Base.is_short_function_def(ex) || Meta.isexpr(ex, :->)

##################
# Public methods #
##################

"""
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

The name of the tracepoint must be a literal string, and it cannot
be changed at runtime.

You can also trace function definitions where name of the tracepoint
will be the name of the function unless it is explicitly provided:

```julia
@tracepoint function f(x)
    x^2
end

@tracepoint "calling g" g(x) = x^2

h = @tracepoint x -> x^2
```

If you don't have Tracy installed, you can install `TracyProfiler_jll`
and start it with `run(TracyProfiler_jll.tracy(); wait=false)`.

```jldoctest
julia> x = rand(10,10);

julia> @tracepoint "multiply" x * x;
```
"""
macro tracepoint(name::String, ex::Expr)
    if _is_func_def(ex)
        return _tracepoint_func(name, ex, __module__, string(__source__.file), __source__.line)
    else
        return _tracepoint(name, ex, __module__, string(__source__.file), __source__.line)
    end
end

macro tracepoint(ex::Expr)
    if _is_func_def(ex)
        return _tracepoint_func(nothing, ex, __module__, string(__source__.file), __source__.line)
    else
        error("expected a function definition if no zone name is provided")
    end
end

function _tracepoint_func(name::Union{String, Nothing}, ex::Expr, mod::Module, filepath::String, line::Int)
    def = splitdef(ex)
    if haskey(def, :name)
        # Grab zone name from function name
        name === nothing && (name = def[:name])
        def[:name] = esc(def[:name])
    else
        name = :var"<anon>"
    end
    def[:args] = map(esc, def[:args])
    if haskey(def, :whereparams)
        def[:whereparams] = map(esc, def[:whereparams])
    end
    def[:body] = _tracepoint(string(name), def[:body], mod, filepath, line)
    return combinedef(def)
end

function _tracepoint(name::String, ex::Expr, mod::Module, filepath::String, line::Int)
    srcloc = TracySrcLoc(name, nothing, filepath, line, 0, mod, true)
    push!(meta(mod), srcloc)

    N = length(meta(mod))
    m_id = getfield(mod, ID)
    return quote
        if tracepoint_enabled(Val($m_id), Val($N))
            if $srcloc.file == C_NULL
                initialize!($srcloc)
            end
            local ctx = @ccall libtracy.___tracy_emit_zone_begin(pointer_from_objref($srcloc)::Ptr{Cvoid},
                                                                 $srcloc.enabled::Cint)::TracyZoneContext
        end
        $(Expr(:tryfinally,
            :($(esc(ex))),
            quote
                if tracepoint_enabled(Val($m_id), Val($N))
                    @ccall libtracy.___tracy_emit_zone_end(ctx::TracyZoneContext)::Cvoid
                end
            end
        ))
    end
end

"""
    configure_tracepoint

Enable/disable a set of tracepoint(s) in the provided modules by invalidating any
existing code containing the tracepoint(s).

!!! warning
    This invalidates the code generated for all functions containing the selected zones.

    This will trigger re-compilation for these functions and may cause undesirable latency.
    It is strongly recommended to use `enable_tracepoint` instead.
"""
function configure_tracepoint(m::Module, enable::Bool; name="", func="", file="")
    m_id = getfield(m, ID)
    for (i, srcloc) in enumerate(meta(m))
        contains(srcloc.name, name) || continue
        contains(srcloc.func, func) || continue
        contains(srcloc.file, file) || continue
        Core.eval(m, :($Tracy.tracepoint_enabled(::Val{$m_id}, ::Val{$i}) = $enable))
    end
    return nothing
end

"""
    enable_tracepoint

Enable/disable a set of tracepoint(s) in the provided modules, based on whether they
match the filters provided for `name`/`func`/`file`.
"""
function enable_tracepoint(m::Module, enable::Bool; name="", func="", file="")
    for srcloc in meta(m)
        contains(srcloc.name, name) || continue
        contains(srcloc.func, func) || continue
        contains(srcloc.file, file) || continue
        srcloc.enabled = enable
    end
    return nothing
end

"""
Register this module's `@tracepoint` callsites with Tracy.jl

This will allow tracepoints to appear in Tracy's Enable/Disable window, even if they
haven't been run yet. Using this macro is optional, but it's recommended to call it
from within your module's `__init__` method.
"""
macro register_tracepoints()
    srclocs = meta(__module__)
    return quote
        push!($modules, $__module__)
        foreach($Tracy.initialize!, $srclocs)
    end
end
