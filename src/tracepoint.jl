# This file is a part of Tracy.jl. License is MIT: See LICENSE.md


##################
# Public methods #
##################

"""
# Tracing Julia code

Code you'd like to trace should be wrapped with `@tracepoint`

    @tracepoint "name" <expression>

Typically the expression will be a `begin-end` block:

    @tracepoint "data aggregation" begin
        # lots of compute here...
    end

The name of the tracepoint must be a literal string, and it cannot
be changed at runtime.

If you don't have Tracy installed, you can install `TracyProfiler_jll`
and start it with `run(TracyProfiler_jll.tracy(); wait=false)`.

```jldoctest
julia> x = rand(10,10);

julia> @tracepoint "multiply" x * x;
```
"""
macro tracepoint(name::String, ex...)
    kws, body = extract_keywords(ex)
    return _tracepoint(name, body, __module__, string(__source__.file), __source__.line; kws...)
end

function _tracepoint(name::String, ex::Expr, mod::Module, filepath::String, line::Int; text=nothing, name2=nothing, color=nothing)
    srcloc = TracySrcLoc(name, nothing, filepath, line, 0, mod, true)
    push!(meta(mod), srcloc)

    N = length(meta(mod))
    m_id = getfield(mod, ID)

    text_expr = text === nothing ? :() :
        quote
            local text = string($text)
            @ccall libtracy.___tracy_emit_zone_text(ctx::TracyZoneContext,
                                                    text::Cstring, length($text)::Csize_t)::Cvoid
        end

    name_expr = name2 === nothing ? :() :
        quote
            local name = $name2
            if name isa Integer
                @ccall libtracy.___tracy_emit_zone_value(ctx::TracyZoneContext,
                                                        name::UInt64)::Cvoid
            else
                name_str = string(name)
                @ccall libtracy.___tracy_emit_zone_name(ctx::TracyZoneContext,
                                                        name_str::Cstring, length(name_str)::Csize_t)::Cvoid
            end
        end

    color_expr = color === nothing ? :() :
    quote
        local tcolor = _tracycolor($color)
        @ccall libtracy.___tracy_emit_zone_color(ctx::TracyZoneContext,
                                                tcolor::Cuint)::Cvoid
    end

    return quote
        if tracepoint_enabled(Val($m_id), Val($N))
            if $srcloc.file == C_NULL
                initialize!($srcloc)
            end
            local ctx = @ccall libtracy.___tracy_emit_zone_begin(pointer_from_objref($srcloc)::Ptr{Cvoid},
                                                                 $srcloc.enabled::Cint)::TracyZoneContext
            $text_expr
            $name_expr
            $color_expr
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
