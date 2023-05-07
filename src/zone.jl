# This file is a part of Tracy.jl. License is MIT: See LICENSE.md


##################
# Public methods #
##################

"""
# Tracing Julia code

Code you'd like to trace should be wrapped with `@zone`

    @zone "name" <expression>

Typically the expression will be a `begin-end` block:

    @zone "data aggregation" begin
        # lots of compute here...
    end

The name of the zone must be a literal string, and it cannot
be changed at runtime.

If you don't have Tracy installed, you can install `TracyProfiler_jll`
and start it with `run(TracyProfiler_jll.tracy(); wait=false)`.

```jldoctest
julia> x = rand(10,10);

julia> @zone "multiply" x * x;
```
"""
macro zone(name::String, ex::Expr)
    return _zone(name, ex, __module__, string(__source__.file), __source__.line)
end

function _zone(name::String, ex::Expr, mod::Module, filepath::String, line::Int)
    m = meta(mod)

    # Deduplicate name strings
    for srcloc in m
        if name == srcloc.zone_name
            name = srcloc.zone_name
            break
        end
    end

    srcloc = DeclaredSrcLoc(name, nothing, filepath, line, 0, mod, 1)
    push!(m, srcloc) # Root it
    return quote
        if $srcloc.module_name == C_NULL
             update_srcloc!($srcloc)
        end
        local ctx = @ccall libtracy.___tracy_emit_zone_begin(Base.pointer_from_objref($srcloc)::Ptr{Cvoid},
                                                             $srcloc.enabled::Cint)::TracyZoneContext
        $(Expr(:tryfinally,
            :($(esc(ex))),
            quote
                @ccall libtracy.___tracy_emit_zone_end(ctx::TracyZoneContext)::Cvoid
            end
        ))
    end
end


"""
    enable_zone

Enable/disable a set of zone(s) in the provided modules, based on whether they
match the filters provided for `name`/`func`/`file`.
"""
function enable_zone(m::Module, enable::Bool; name="", func="", file="")
    for srcloc in meta(m)
        contains(srcloc.name, name) || continue
        contains(srcloc.func, func) || continue
        contains(srcloc.file, file) || continue
        srcloc.enabled = enable
    end
    return nothing
end

"""
Register this module's `@zone` callsites with Tracy.jl

This will allow zones to appear in Tracy's Enable/Disable window, even if they
haven't been run yet. Using this macro is optional, but it's recommended to call it
from within your module's `__init__` method.
"""
macro register_zones()
    srclocs = meta(__module__)
    return quote
        push!($modules, $__module__)
        for i = 1:length($srclocs)
            update_srcloc!(srclocs[i])
        end
    end
end
