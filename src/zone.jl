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
    for (srcloc, _) in m
        if name == srcloc.name
            name = srcloc.name
            break
        end
    end
    srcloc = JuliaSrcLoc(name, nothing, filepath, line, 0)
    c_srcloc_ref = Ref(DeclaredSrcLoc(TracySrcLoc(C_NULL, C_NULL, C_NULL, 0, 0), C_NULL, 1))

    push!(m, Pair(srcloc, c_srcloc_ref))

    return quote
        c_srcloc = $c_srcloc_ref[]
        if c_srcloc.module_name == C_NULL
            update_srcloc!($c_srcloc_ref, $srcloc, $mod)
        end
        local ctx = @ccall libtracy.___tracy_emit_zone_begin($c_srcloc_ref::Ptr{Cvoid},
                                                             c_srcloc.enabled::Cint)::TracyZoneContext

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
    for (srcloc, c_srcloc) in meta(m)
        contains(srcloc.name, name) || continue
        contains(srcloc.func, func) || continue
        contains(srcloc.file, file) || continue
        if ((c_srcloc[].enabled == 0 && enable) || (c_srcloc[].enabled == 1 && !enable))
            c_srcloc[] = DeclaredSrcLoc(c_srcloc[].srcloc, c_srcloc[].module_name, enable)
        end
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
            Tracy.update_srcloc!($srclocs[i].second, $srclocs[i].first, $__module__)
        end
    end
end

###################
# Private methods #
###################

"""
A 'Julia' version of the data contained in `DeclaredSrcLoc`

The redundant data structure is required for two reasons:
  1. Julia provides no facility for C pointers to be correctly
     serialized/de-serialized across pre-compile.
  2. Any pointers needs to have their memory backed by Julia
     objects, so the `JuliaSrcLoc` objects keep the referenced
     objects used by `DeclaredSrcLoc` alive in the GC
"""
struct JuliaSrcLoc
    name::Union{String, Nothing}
    func::Union{String, Nothing}
    file::String
    line::UInt32
    color::UInt32
end


"""
Update a C ABI-compatible `DeclaredSrcLoc` with contents taken from a `JuliaSrcLoc` object.
"""
function update_srcloc!(c_srcloc::Ref{DeclaredSrcLoc}, srcloc::JuliaSrcLoc, m::Module)
    name = !isnothing(srcloc.name) ? pointer(srcloc.name) : C_NULL
    func = !isnothing(srcloc.func) ? pointer(srcloc.func) : pointer(unknown_string)
    base_data = TracySrcLoc(name, func, pointer(srcloc.file), srcloc.line, srcloc.color)
    c_srcloc[] = DeclaredSrcLoc(base_data, pointer(string(nameof(m))), 1)
    # ccall((:___tracy_send_srcloc, libtracy), Cvoid, (Ptr{DeclaredSrcLoc},), c_srcloc)
end
