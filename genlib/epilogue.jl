"""
This struct effectively inherits from TracySrcLoc and extends it with several
Julia-specific/experimental features.

Note: This C correspondent of this definition only exists on my "experimental"
branch of Tracy, but its usage is designed to be backwards-compatible with prior
Tracy versions.
"""
struct __tracy_declared_source_location_data
    srcloc::___tracy_source_location_data
    module_name::Ptr{UInt8}   # nameof(__module__) (Julia-specific)
    enabled::UInt64           # 0 = runtime-disabled, 1 = runtime-enabled, 0xff = compile-time-disabled
end
