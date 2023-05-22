# This file is a part of Tracy.jl. License is MIT: See LICENSE.md


##################
# Public methods #
##################

"""
    @tracepoint <name> enabled=<expr> color=<expr> <expression>

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

The (default) color of the zone can be configured
with the `color` keyword argument to the macro and it should evaluate (at macro expansion time) to:
$color_docstr

```jldoctest
julia> x = rand(10,10);

julia> @tracepoint "multiply" x * x;

julia> col = 0x00FF00; name = "sqrt";

julia> @tracepoint name color=col sqrt(x) # green
```

If you don't have Tracy installed, you can install `TracyProfiler_jll`
and start it with `run(TracyProfiler_jll.tracy(); wait=false)`.
"""
macro tracepoint(name, ex...)
    kws, body = extract_keywords(ex)
    kws_evaluated = Dict{Symbol, Any}()
    name_eval = try_static_eval(__module__, name)
    if name_eval === nothing
        error("name for tracepoint could not be statically evaluated")
    end
    for (k, v) in kws
        v_eval = try_static_eval(__module__, v)
        if v_eval === nothing
            error("value for keyword argument $k could not be statically evaluated")
        end
        kws_evaluated[k] = v_eval
    end
    return _tracepoint(string(name_eval), body, __module__, string(__source__.file), __source__.line; kws_evaluated...)
end

function _tracepoint(name::String, ex::Expr, mod::Module, filepath::String, line::Int; color::Union{Integer,Symbol,NTuple{3,Integer},Nothing}=0)
    srcloc = TracySrcLoc(name, nothing, filepath, line, _tracycolor(color), mod, true)
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
