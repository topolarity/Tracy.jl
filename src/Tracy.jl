# This file is a part of Tracy.jl. License is MIT: See LICENSE.md

"""
    Tracy

The `Tracy` module provides the `@zone` macro which can be used to create
scoped regions for profiling with Tracy.

`@zone`s can be runtime enabled/disabled with `enable_zone` or they
can be erased from the generated code entirely using invalidation with
`configure_zone`. The latter is effectively a "compile-time" enable/disable
for tracing zones for ultra-low overhead.

If Julia was built with the compile-time flag `WITH_TRACY` enabled, the recorded
traces will also include data from various parts of the Julia runtime, including
codegen, GC, and runtime-internal mutexes/locks.
"""
module Tracy

using LibTracyClient_jll: libTracyClient
using Libdl: dllist, dlopen

include("cffi.jl")
include("zone.jl")

export @zone

# Remaining public API is:
#   - `enable_zone`
#   - `configure_zone`
#   - `@register_zones`

###################
# Private methods #
###################

const META = gensym(:meta)
const METAType = Vector{DeclaredSrcLoc}

function meta(m::Module; autoinit::Bool=true)
    m = Base.moduleroot(m)
    if !isdefined(m, META) || getfield(m, META) === nothing
        autoinit ? initmeta(m) : return nothing
    end
    return getfield(m, META)::METAType
end

function initmeta(m::Module)
    m = Base.moduleroot(m)
    if !isdefined(m, META) || getfield(m, META) === nothing
        Core.eval(m, :($META = $(METAType())))
    end
    nothing
end

const modules = Module[]
const unknown_string = "<unknown>"

const BASE_TRACY_LIB = let
    base_tracy_libs = filter(contains("libTracyClient"), dllist())
    isempty(base_tracy_libs) ? nothing : first(base_tracy_libs)
end
libtracy::String = ""

# Register telemetry callbacks with Tracy
#
# This is what allows `@zone`s to be toggled from within the Tracy GUI
function __init__()
    global libtracy = something(BASE_TRACY_LIB, libTracyClient)
    toggle_fn = @cfunction((data, srcloc, enable_ptr) -> begin
        enable = unsafe_load(enable_ptr)
        for m in modules
            for srcloc in meta(m)
                if pointer_from_objref(srcloc) == srcloc
                    srcloc.enabled = enable
                    return nothing
                end
            end
        end
    end, Cvoid, (Ptr{Cvoid}, Ptr{DeclaredSrcLoc}, Ptr{UInt64}))
    # ccall(:___tracy_zone_toggle_register,
          # #(:___tracy_emit_zone_begin, libTracyClient),
          # Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), toggle_fn, C_NULL)
end

end # module Tracy
