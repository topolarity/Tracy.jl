# This file is a part of Tracy.jl. License is MIT: See LICENSE.md

###########################
# Tracy C FFI Struct Defs #
###########################

mutable struct TracySrcLoc
    # These are the standard fields for ___tracy_source_location_data
    zone_name::Ptr{UInt8}        # (optional)
    function_name::Ptr{UInt8}    # __func__
    file::Ptr{UInt8}             # __file__
    line::UInt32                 # __line__
    color::UInt32                # 0 for default color

    # Note: This C correspondent of the following fields only exists on my "experimental"
    # branch of Tracy, but its usage is designed to be backwards-compatible with prior
    # Tracy versions:
    module_name::Ptr{UInt8} # nameof(__module__) (Julia-specific)
    enabled::Cint        # 0 = runtime-disabled, 1 = runtime-enabled, 0xff = compile-time-disabled

    # These are used to reinitialize the pointers above since
    # pointers are only valid in a given Julia session.
    zone_name_str::Union{String, Nothing}
    function_name_str::Union{String, Nothing}
    file_str::String
    module_name_str::String
end

function TracySrcLoc(name::Union{String, Nothing}, function_name::Union{String, Nothing}, file::String, line::Integer, color::Integer, mod::Module, enabled::Bool)
    src = TracySrcLoc(C_NULL, C_NULL, C_NULL, line, color, C_NULL, enabled, name, function_name, file, string(mod))
    initialize!(src)
    return src
end

const unknown_string = "<unknown>"

"""
Update the pointers for a C ABI-compatible ` TracySrcLoc` to be valid for this
running Julia session.
"""
@noinline function initialize!(srcloc::TracySrcLoc)
    srcloc.zone_name     = isnothing(srcloc.zone_name_str)     ? C_NULL                  : pointer(srcloc.zone_name_str)
    srcloc.function_name = isnothing(srcloc.function_name_str) ? pointer(unknown_string) : pointer(srcloc.function_name_str)
    srcloc.file = pointer(srcloc.file_str)
    srcloc.module_name = pointer(srcloc.module_name_str)
    return srcloc
    # @ccall libtracy.___tracy_send_srcloc(pointer_from_objref(srcloc)::Ptr{TracySrcLoc})::Cvoid
end

# ___tracy_c_zone_context
struct TracyZoneContext
    id::UInt32
    active::Cint
end
