# This file is a part of Tracy.jl. License is MIT: See LICENSE.md

###########################
# Tracy C FFI Struct Defs #
###########################

# ___tracy_c_zone_context
struct TracyZoneContext
    id::UInt32
    active::Cint
end

"""
This struct effectively inherits from ___tracy_source_location_data and extends it with several
Julia-specific/experimental features.

Note: This C correspondent of this definition only exists on my "experimental"
branch of Tracy, but its usage is designed to be backwards-compatible with prior
Tracy versions.
"""
mutable struct DeclaredSrcLoc
    # begin # ___tracy_source_location_data
    zone_name::Cstring        # (optional)
    function_name::Cstring    # __func__
    file::Cstring             # __file__
    line::UInt32              # __line__
    color::UInt32             # 0 for default color
    # end # ___tracy_source_location_data

    # begin Julia-specific fields
    module_name::Ptr{UInt8}   # nameof(__module__) (Julia-specific)
    enabled::UInt64           # 0 = runtime-disabled, 1 = runtime-enabled, 0xff = compile-time-disabled
    # end Julia-specific fields

    # Roots
    zone_name_str::Union{String, Nothing}
    function_name_str::Union{String, Nothing}
    file_str::String
    module_name_str::String
end

function DeclaredSrcLoc(zone_name::Union{String, Nothing}, function_name::Union{String, Nothing}, file::String,
                       line::Integer, color::Integer, mod::Module, enabled::Integer)
    mod_str = string(mod)
    zone_name_ptr = !isnothing(zone_name) ? pointer(zone_name) : C_NULL
    function_name_ptr = !isnothing(function_name) ? pointer(function_name) : C_NULL
    return DeclaredSrcLoc(zone_name_ptr, function_name_ptr, pointer(file), line, color, pointer(mod_str), enabled,
                         zone_name, function_name, file, mod_str)
end


"""
Return a new `DeclaredSrcLoc` with refreshed pointers (needed after they have been nulled by the serializer).
"""
function update_srcloc!(srcloc::DeclaredSrcLoc)
    srcloc.zone_name_str === nothing || (srcloc.zone_name = pointer(srcloc.zone_name_str))
    srcloc.function_name_str === nothing || (srcloc.function_name = pointer(srcloc.function_name_str))
    srcloc.file = pointer(srcloc.file_str)
    srcloc.module_name = pointer(srcloc.module_name_str)
    # ccall((:___tracy_send_srcloc, libtracy), Cvoid, (Ptr{DeclaredSrcLoc},), Base.pointer_from_objref(srcloc))
end
