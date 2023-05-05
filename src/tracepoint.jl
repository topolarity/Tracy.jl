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
macro tracepoint(name::String, ex::Expr)
    return _tracepoint(name, ex, __module__, string(__source__.file), __source__.line)
end

function _tracepoint(name::String, ex::Expr, mod::Module, filepath::String, line::Int)
    srcloc = JuliaSrcLoc(name, nothing, filepath, line, 0)
    c_srcloc = Ref{DeclaredSrcLoc}(DeclaredSrcLoc(TracySrcLoc(C_NULL, C_NULL, C_NULL, 0, 0), C_NULL, 1))
    push!(meta(mod), Pair(srcloc, c_srcloc))

    N = length(meta(mod))
    m_id = getfield(mod, ID)
    return quote
        if tracepoint_enabled(Val($m_id), Val($N))
            if $c_srcloc[].module_name == C_NULL
                update_srcloc!($c_srcloc, $srcloc, $mod)
            end
            local ptr = pointer_from_objref($c_srcloc)
            local ctx = ccall(
                        (:___tracy_emit_zone_begin, find_libtracy()),
                        TracyZoneContext, (Ptr{Cvoid}, Cint),
                        ptr, unsafe_load(Ptr{DeclaredSrcLoc}(ptr)).enabled)
        end
        $(esc(ex))
        if tracepoint_enabled(Val($m_id), Val($N))
            ccall((:___tracy_emit_zone_end, find_libtracy()),
                  Cvoid, (TracyZoneContext,), ctx)
        end
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
    for (i, (srcloc, _)) in enumerate(meta(m))
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
    m_id = getfield(m, ID)
    for (i, (srcloc, c_srcloc)) in enumerate(meta(m))
        contains(srcloc.name, name) || continue
        contains(srcloc.func, func) || continue
        contains(srcloc.file, file) || continue
        if ((c_srcloc[] == 0 && enable) || (c_srcloc[] == 1 && !enable))
            c_srcloc[] = DeclaredSrcLoc(c_srcloc[].srcloc, c_srcloc[].module_name, enable)
        end
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
    # ccall((:___tracy_send_srcloc, find_libtracy()), Cvoid, (Ptr{DeclaredSrcLoc},), c_srcloc)
end
