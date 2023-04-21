# This file is a part of Tracy.jl. License is MIT: See LICENSE.md

###########################
# Tracy C FFI Struct Defs #
###########################

# ___tracy_source_location_data
struct TracySrcLoc
    zone_name::Cstring        # (optional)
    function_name::Cstring    # __func__
    file::Cstring             # __file__
    line::UInt32              # __line__
    color::UInt32             # 0 for default color
end

# ___tracy_c_zone_context
struct TracyZoneContext
    id::UInt32
    active::Cint
end

"""
This struct effectively inherits from TracySrcLoc and extends it with several 
Julia-specific/experimental features.

Note: This C correspondent of this definition only exists on my "experimental"
branch of Tracy, but its usage is designed to be backwards-compatible with prior
Tracy versions.
"""
struct DeclaredSrcLoc
    srcloc::TracySrcLoc
    module_name::Ptr{UInt8}   # nameof(__module__) (Julia-specific)
    enabled::UInt64           # 0 = runtime-disabled, 1 = runtime-enabled, 0xff = compile-time-disabled
end
