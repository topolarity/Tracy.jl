# This file is a part of Tracy.jl. License is MIT: See LICENSE.md

"""
    Tracy

The `Tracy` module provides the `@tracepoint` macro which can be used to create
scoped regions for profiling with Tracy.

`@tracepoint`s can be runtime enabled/disabled with `enable_tracepoint` or they
can be erased from the generated code entirely using invalidation with
`configure_tracepoint`. The latter is effectively a "compile-time" enable/disable
for tracing zones for ultra-low overhead.

If Julia was built with the compile-time flag `WITH_TRACY` enabled, the recorded
traces will also include data from various parts of the Julia runtime, including
codegen, GC, and runtime-internal mutexes/locks.
"""
module Tracy

using LibTracyClient_jll: libTracyClient
using Libdl: dllist, dlopen
using ExprTools: splitdef, combinedef
using Preferences: load_preference, has_preference

const color_docstr = """
- An integer: The hex code of the color as `0xRRGGBB`.
- A symbol: Can take the value `:black`, `:blue`, `:green`, `:cyan`, `:red`, `:magenta`, `:yellow`, `:white`,
  `:light_black`, `:light_blue`, `:light_green`, `:light_cyan`, `:light_red`, `:light_magenta`, `:light_yellow`, `:light_white`.
- A tuple of three integers: The RGB value `(R, G, B)` where each value is in the range 0..255.
"""

include("utils.jl")
include("cffi.jl")
include("colors.jl")
include("tracepoint.jl")
include("msg.jl")
include("plot.jl")


export @tracepoint, tracyplot, tracyplot_config, tracymsg, wait_for_tracy

# Remaining public API is:
#   - `enable_tracepoint`
#   - `@register_tracepoints`

###################
# Private methods #
###################

const META = gensym(:meta)
const METAType = Vector{TracySrcLoc}

function meta(m::Module; autoinit::Bool=true)
    if !isdefined(m, META) || getfield(m, META) === nothing
        autoinit ? initmeta(m) : return nothing
    end
    return getfield(m, META)::METAType
end

function initmeta(m::Module)
    if !isdefined(m, META) || getfield(m, META) === nothing
        Core.eval(m, :($META = $(METAType())))
    end
    nothing
end

const modules = Set{Module}()

const BASE_TRACY_LIB = let
    base_tracy_libs = filter(contains("libTracyClient"), dllist())
    isempty(base_tracy_libs) ? nothing : first(base_tracy_libs)
end
libtracy::String = ""

# Register telemetry callbacks with Tracy
#
# This is what allows `@tracepoint`s to be toggled from within the Tracy GUI
function __init__()
    global libtracy = something(BASE_TRACY_LIB, libTracyClient)
    toggle_fn = @cfunction((data, tracy_srcloc_ptr, enable_ptr) -> begin
        enable = unsafe_load(enable_ptr)
        for m in modules
            for (i, srcloc) in enumerate(meta(m))
                if pointer_from_objref(srcloc) == tracy_srcloc_ptr
                    srcloc.enabled = enable
                    return nothing
                end
            end
        end
    end, Cvoid, (Ptr{Cvoid}, Ptr{TracySrcLoc}, Ptr{UInt64}))
    # ccall(:___tracy_zone_toggle_register,
          # #(:___tracy_emit_zone_begin, libTracyClient),
          # Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}), toggle_fn, C_NULL)
end

end # module Tracy
