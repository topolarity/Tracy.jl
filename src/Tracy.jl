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

include("LibTracyClient.jl")
const DeclaredSrcLoc = LibTracyClient.__tracy_declared_source_location_data

include("./tracepoint.jl")


export @tracepoint

# Remaining public API is:
#   - `enable_tracepoint`
#   - `configure_tracepoint`
#   - `@register_tracepoints`

###################
# Private methods #
###################

const ID = gensym(:id)
const META = gensym(:meta)
const METAType = Vector{Pair{JuliaSrcLoc, Ref{DeclaredSrcLoc}}}

function meta(m::Module; autoinit::Bool=true)
    if !isdefined(m, META) || getfield(m, META) === nothing
        autoinit ? initmeta(m) : return nothing
    end
    return getfield(m, META)::METAType
end

function initmeta(m::Module)
    if !isdefined(m, META) || getfield(m, META) === nothing
        Core.eval(m, :($META = $(METAType())))
        Core.eval(m, :($ID() = nothing))
        Core.eval(m, :($Tracy.tracepoint_enabled(::Val{$ID}, ::Val) = true))
    end
    nothing
end

const modules = Module[]
const unknown_string = "<unknown>"

"""
    tracepoint_enabled

This function is used to implement a dispatch-based technique for "compile-time"
enable/disable of individual tracepoints. The first parameter is a unique identifier
generated for each client Module, and the second is an index corresponding to the
`@tracepoint` generated in the module.

These parameters are statically-known at all call-sites and the return value is
either always true or always false, which makes it trivial for the compiler to elide
the call to be totally elided and propagate its result, including any dead profiling
zones that we'd like eliminated.
"""
tracepoint_enabled(::Val, ::Val) = true

# Register telemetry callbacks with Tracy
#
# This is what allows `@tracepoint`s to be toggled from within the Tracy GUI
function __init__()
    toggle_fn = @cfunction((data, srcloc, enable_ptr) -> begin
        enable = unsafe_load(enable_ptr)
        for m in modules
            for (i, (_, c_srcloc)) in enumerate(meta(m))
                if pointer_from_objref(c_srcloc) == srcloc
                    m_id = getfield(m, ID)
                    old_enable = c_srcloc[].enabled
                    if enable != old_enable
                        if old_enable == 0xFF
                            Core.eval(m, :($Tracy.tracepoint_enabled(::Val{$m_id}, ::Val{$i}) = true))
                        elseif enable == 0xFF
                            Core.eval(m, :($Tracy.tracepoint_enabled(::Val{$m_id}, ::Val{$i}) = false))
                        end
                        c_srcloc[] = DeclaredSrcLoc(c_srcloc[].srcloc, c_srcloc[].module_name, enable)
                    end
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
