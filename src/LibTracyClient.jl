module LibTracyClient

using LibTracyClient_jll: libTracyClient
using Libdl: dllist, dlopen

const BASE_TRACY_LIB = let
    base_tracy_libs = filter(contains("libTracyClient"), dllist())
    isempty(base_tracy_libs) ? nothing : first(base_tracy_libs)
end
libtracyclient::String = ""

function __init__()
    global libtracyclient = something(BASE_TRACY_LIB, libTracyClient)
end


"""
    ___tracy_set_thread_name(name)


### Prototype
```c
TRACY_API void ___tracy_set_thread_name( const char* name );
```
"""
function ___tracy_set_thread_name(name)
    @ccall libtracyclient.___tracy_set_thread_name(name::Ptr{Cchar})::Cvoid
end

struct ___tracy_c_zone_context
    id::UInt32
    active::Cint
end

"""
Some containers don't support storing const types.
This struct, as visible to user, is immutable, so treat it as if const was declared here.
"""
const TracyCZoneCtx = ___tracy_c_zone_context

struct ___tracy_source_location_data
    name::Ptr{Cchar}
    _function::Ptr{Cchar}
    file::Ptr{Cchar}
    line::UInt32
    color::UInt32
end

"""
    ___tracy_emit_zone_begin(srcloc, active)


### Prototype
```c
TRACY_API TracyCZoneCtx ___tracy_emit_zone_begin( const struct ___tracy_source_location_data* srcloc, int active );
```
"""
function ___tracy_emit_zone_begin(srcloc, active)
    @ccall libtracyclient.___tracy_emit_zone_begin(srcloc::Ptr{___tracy_source_location_data}, active::Cint)::TracyCZoneCtx
end

"""
    ___tracy_emit_zone_end(ctx)


### Prototype
```c
TRACY_API void ___tracy_emit_zone_end( TracyCZoneCtx ctx );
```
"""
function ___tracy_emit_zone_end(ctx)
    @ccall libtracyclient.___tracy_emit_zone_end(ctx::TracyCZoneCtx)::Cvoid
end

"""
    ___tracy_emit_zone_text(ctx, txt, size)


### Prototype
```c
TRACY_API void ___tracy_emit_zone_text( TracyCZoneCtx ctx, const char* txt, size_t size );
```
"""
function ___tracy_emit_zone_text(ctx, txt, size)
    @ccall libtracyclient.___tracy_emit_zone_text(ctx::TracyCZoneCtx, txt::Ptr{Cchar}, size::Csize_t)::Cvoid
end

"""
    ___tracy_emit_zone_name(ctx, txt, size)


### Prototype
```c
TRACY_API void ___tracy_emit_zone_name( TracyCZoneCtx ctx, const char* txt, size_t size );
```
"""
function ___tracy_emit_zone_name(ctx, txt, size)
    @ccall libtracyclient.___tracy_emit_zone_name(ctx::TracyCZoneCtx, txt::Ptr{Cchar}, size::Csize_t)::Cvoid
end

"""
    ___tracy_emit_zone_color(ctx, color)


### Prototype
```c
TRACY_API void ___tracy_emit_zone_color( TracyCZoneCtx ctx, uint32_t color );
```
"""
function ___tracy_emit_zone_color(ctx, color)
    @ccall libtracyclient.___tracy_emit_zone_color(ctx::TracyCZoneCtx, color::UInt32)::Cvoid
end

"""
    ___tracy_emit_zone_value(ctx, value)


### Prototype
```c
TRACY_API void ___tracy_emit_zone_value( TracyCZoneCtx ctx, uint64_t value );
```
"""
function ___tracy_emit_zone_value(ctx, value)
    @ccall libtracyclient.___tracy_emit_zone_value(ctx::TracyCZoneCtx, value::UInt64)::Cvoid
end

"""
    ___tracy_emit_memory_alloc(ptr, size, secure)


### Prototype
```c
TRACY_API void ___tracy_emit_memory_alloc( const void* ptr, size_t size, int secure );
```
"""
function ___tracy_emit_memory_alloc(ptr, size, secure)
    @ccall libtracyclient.___tracy_emit_memory_alloc(ptr::Ptr{Cvoid}, size::Csize_t, secure::Cint)::Cvoid
end

"""
    ___tracy_emit_memory_free(ptr, secure)


### Prototype
```c
TRACY_API void ___tracy_emit_memory_free( const void* ptr, int secure );
```
"""
function ___tracy_emit_memory_free(ptr, secure)
    @ccall libtracyclient.___tracy_emit_memory_free(ptr::Ptr{Cvoid}, secure::Cint)::Cvoid
end

"""
    ___tracy_emit_memory_alloc_named(ptr, size, secure, name)


### Prototype
```c
TRACY_API void ___tracy_emit_memory_alloc_named( const void* ptr, size_t size, int secure, const char* name );
```
"""
function ___tracy_emit_memory_alloc_named(ptr, size, secure, name)
    @ccall libtracyclient.___tracy_emit_memory_alloc_named(ptr::Ptr{Cvoid}, size::Csize_t, secure::Cint, name::Ptr{Cchar})::Cvoid
end

"""
    ___tracy_emit_memory_free_named(ptr, secure, name)


### Prototype
```c
TRACY_API void ___tracy_emit_memory_free_named( const void* ptr, int secure, const char* name );
```
"""
function ___tracy_emit_memory_free_named(ptr, secure, name)
    @ccall libtracyclient.___tracy_emit_memory_free_named(ptr::Ptr{Cvoid}, secure::Cint, name::Ptr{Cchar})::Cvoid
end

"""
    ___tracy_emit_message(txt, size, callstack)


### Prototype
```c
TRACY_API void ___tracy_emit_message( const char* txt, size_t size, int callstack );
```
"""
function ___tracy_emit_message(txt, size, callstack)
    @ccall libtracyclient.___tracy_emit_message(txt::Ptr{Cchar}, size::Csize_t, callstack::Cint)::Cvoid
end

"""
    ___tracy_emit_messageL(txt, callstack)


### Prototype
```c
TRACY_API void ___tracy_emit_messageL( const char* txt, int callstack );
```
"""
function ___tracy_emit_messageL(txt, callstack)
    @ccall libtracyclient.___tracy_emit_messageL(txt::Ptr{Cchar}, callstack::Cint)::Cvoid
end

"""
    ___tracy_emit_messageC(txt, size, color, callstack)


### Prototype
```c
TRACY_API void ___tracy_emit_messageC( const char* txt, size_t size, uint32_t color, int callstack );
```
"""
function ___tracy_emit_messageC(txt, size, color, callstack)
    @ccall libtracyclient.___tracy_emit_messageC(txt::Ptr{Cchar}, size::Csize_t, color::UInt32, callstack::Cint)::Cvoid
end

"""
    ___tracy_emit_messageLC(txt, color, callstack)


### Prototype
```c
TRACY_API void ___tracy_emit_messageLC( const char* txt, uint32_t color, int callstack );
```
"""
function ___tracy_emit_messageLC(txt, color, callstack)
    @ccall libtracyclient.___tracy_emit_messageLC(txt::Ptr{Cchar}, color::UInt32, callstack::Cint)::Cvoid
end

"""
    ___tracy_emit_frame_mark(name)


### Prototype
```c
TRACY_API void ___tracy_emit_frame_mark( const char* name );
```
"""
function ___tracy_emit_frame_mark(name)
    @ccall libtracyclient.___tracy_emit_frame_mark(name::Ptr{Cchar})::Cvoid
end

"""
    ___tracy_emit_frame_mark_start(name)


### Prototype
```c
TRACY_API void ___tracy_emit_frame_mark_start( const char* name );
```
"""
function ___tracy_emit_frame_mark_start(name)
    @ccall libtracyclient.___tracy_emit_frame_mark_start(name::Ptr{Cchar})::Cvoid
end

"""
    ___tracy_emit_frame_mark_end(name)


### Prototype
```c
TRACY_API void ___tracy_emit_frame_mark_end( const char* name );
```
"""
function ___tracy_emit_frame_mark_end(name)
    @ccall libtracyclient.___tracy_emit_frame_mark_end(name::Ptr{Cchar})::Cvoid
end

"""
    ___tracy_emit_frame_image(image, w, h, offset, flip)


### Prototype
```c
TRACY_API void ___tracy_emit_frame_image( const void* image, uint16_t w, uint16_t h, uint8_t offset, int flip );
```
"""
function ___tracy_emit_frame_image(image, w, h, offset, flip)
    @ccall libtracyclient.___tracy_emit_frame_image(image::Ptr{Cvoid}, w::UInt16, h::UInt16, offset::UInt8, flip::Cint)::Cvoid
end

"""
    ___tracy_emit_plot(name, val)


### Prototype
```c
TRACY_API void ___tracy_emit_plot( const char* name, double val );
```
"""
function ___tracy_emit_plot(name, val)
    @ccall libtracyclient.___tracy_emit_plot(name::Ptr{Cchar}, val::Cdouble)::Cvoid
end

"""
    ___tracy_emit_plot_float(name, val)


### Prototype
```c
TRACY_API void ___tracy_emit_plot_float( const char* name, float val );
```
"""
function ___tracy_emit_plot_float(name, val)
    @ccall libtracyclient.___tracy_emit_plot_float(name::Ptr{Cchar}, val::Cfloat)::Cvoid
end

"""
    ___tracy_emit_plot_int(name, val)


### Prototype
```c
TRACY_API void ___tracy_emit_plot_int( const char* name, int64_t val );
```
"""
function ___tracy_emit_plot_int(name, val)
    @ccall libtracyclient.___tracy_emit_plot_int(name::Ptr{Cchar}, val::Int64)::Cvoid
end

"""
    ___tracy_emit_message_appinfo(txt, size)


### Prototype
```c
TRACY_API void ___tracy_emit_message_appinfo( const char* txt, size_t size );
```
"""
function ___tracy_emit_message_appinfo(txt, size)
    @ccall libtracyclient.___tracy_emit_message_appinfo(txt::Ptr{Cchar}, size::Csize_t)::Cvoid
end

"""
    ___tracy_emit_zone_begin_callstack(srcloc, depth, active)


### Prototype
```c
TRACY_API TracyCZoneCtx ___tracy_emit_zone_begin_callstack( const struct ___tracy_source_location_data* srcloc, int depth, int active );
```
"""
function ___tracy_emit_zone_begin_callstack(srcloc, depth, active)
    @ccall libtracyclient.___tracy_emit_zone_begin_callstack(srcloc::Ptr{___tracy_source_location_data}, depth::Cint, active::Cint)::TracyCZoneCtx
end

"""
    ___tracy_emit_memory_alloc_callstack(ptr, size, depth, secure)


### Prototype
```c
TRACY_API void ___tracy_emit_memory_alloc_callstack( const void* ptr, size_t size, int depth, int secure );
```
"""
function ___tracy_emit_memory_alloc_callstack(ptr, size, depth, secure)
    @ccall libtracyclient.___tracy_emit_memory_alloc_callstack(ptr::Ptr{Cvoid}, size::Csize_t, depth::Cint, secure::Cint)::Cvoid
end

"""
    ___tracy_emit_memory_free_callstack(ptr, depth, secure)


### Prototype
```c
TRACY_API void ___tracy_emit_memory_free_callstack( const void* ptr, int depth, int secure );
```
"""
function ___tracy_emit_memory_free_callstack(ptr, depth, secure)
    @ccall libtracyclient.___tracy_emit_memory_free_callstack(ptr::Ptr{Cvoid}, depth::Cint, secure::Cint)::Cvoid
end

"""
    ___tracy_emit_memory_alloc_callstack_named(ptr, size, depth, secure, name)


### Prototype
```c
TRACY_API void ___tracy_emit_memory_alloc_callstack_named( const void* ptr, size_t size, int depth, int secure, const char* name );
```
"""
function ___tracy_emit_memory_alloc_callstack_named(ptr, size, depth, secure, name)
    @ccall libtracyclient.___tracy_emit_memory_alloc_callstack_named(ptr::Ptr{Cvoid}, size::Csize_t, depth::Cint, secure::Cint, name::Ptr{Cchar})::Cvoid
end

"""
    ___tracy_emit_memory_free_callstack_named(ptr, depth, secure, name)


### Prototype
```c
TRACY_API void ___tracy_emit_memory_free_callstack_named( const void* ptr, int depth, int secure, const char* name );
```
"""
function ___tracy_emit_memory_free_callstack_named(ptr, depth, secure, name)
    @ccall libtracyclient.___tracy_emit_memory_free_callstack_named(ptr::Ptr{Cvoid}, depth::Cint, secure::Cint, name::Ptr{Cchar})::Cvoid
end

"""
    ___tracy_connected()


### Prototype
```c
TRACY_API int ___tracy_connected(void);
```
"""
function ___tracy_connected()
    @ccall libtracyclient.___tracy_connected()::Cint
end

struct ___tracy_gpu_time_data
    gpuTime::Int64
    queryId::UInt16
    context::UInt8
end

struct ___tracy_gpu_zone_begin_data
    srcloc::UInt64
    queryId::UInt16
    context::UInt8
end

struct ___tracy_gpu_zone_begin_callstack_data
    srcloc::UInt64
    depth::Cint
    queryId::UInt16
    context::UInt8
end

struct ___tracy_gpu_zone_end_data
    queryId::UInt16
    context::UInt8
end

struct ___tracy_gpu_new_context_data
    gpuTime::Int64
    period::Cfloat
    context::UInt8
    flags::UInt8
    type::UInt8
end

struct ___tracy_gpu_context_name_data
    context::UInt8
    name::Ptr{Cchar}
    len::UInt16
end

struct ___tracy_gpu_calibration_data
    gpuTime::Int64
    cpuDelta::Int64
    context::UInt8
end

"""
    ___tracy_alloc_srcloc(line, source, sourceSz, _function, functionSz)


### Prototype
```c
TRACY_API uint64_t ___tracy_alloc_srcloc( uint32_t line, const char* source, size_t sourceSz, const char* function, size_t functionSz );
```
"""
function ___tracy_alloc_srcloc(line, source, sourceSz, _function, functionSz)
    @ccall libtracyclient.___tracy_alloc_srcloc(line::UInt32, source::Ptr{Cchar}, sourceSz::Csize_t, _function::Ptr{Cchar}, functionSz::Csize_t)::UInt64
end

"""
    ___tracy_alloc_srcloc_name(line, source, sourceSz, _function, functionSz, name, nameSz)


### Prototype
```c
TRACY_API uint64_t ___tracy_alloc_srcloc_name( uint32_t line, const char* source, size_t sourceSz, const char* function, size_t functionSz, const char* name, size_t nameSz );
```
"""
function ___tracy_alloc_srcloc_name(line, source, sourceSz, _function, functionSz, name, nameSz)
    @ccall libtracyclient.___tracy_alloc_srcloc_name(line::UInt32, source::Ptr{Cchar}, sourceSz::Csize_t, _function::Ptr{Cchar}, functionSz::Csize_t, name::Ptr{Cchar}, nameSz::Csize_t)::UInt64
end

"""
    ___tracy_emit_zone_begin_alloc(srcloc, active)


### Prototype
```c
TRACY_API TracyCZoneCtx ___tracy_emit_zone_begin_alloc( uint64_t srcloc, int active );
```
"""
function ___tracy_emit_zone_begin_alloc(srcloc, active)
    @ccall libtracyclient.___tracy_emit_zone_begin_alloc(srcloc::UInt64, active::Cint)::TracyCZoneCtx
end

"""
    ___tracy_emit_zone_begin_alloc_callstack(srcloc, depth, active)


### Prototype
```c
TRACY_API TracyCZoneCtx ___tracy_emit_zone_begin_alloc_callstack( uint64_t srcloc, int depth, int active );
```
"""
function ___tracy_emit_zone_begin_alloc_callstack(srcloc, depth, active)
    @ccall libtracyclient.___tracy_emit_zone_begin_alloc_callstack(srcloc::UInt64, depth::Cint, active::Cint)::TracyCZoneCtx
end

"""
    ___tracy_emit_gpu_zone_begin(arg1)


### Prototype
```c
TRACY_API void ___tracy_emit_gpu_zone_begin( const struct ___tracy_gpu_zone_begin_data );
```
"""
function ___tracy_emit_gpu_zone_begin(arg1)
    @ccall libtracyclient.___tracy_emit_gpu_zone_begin(arg1::___tracy_gpu_zone_begin_data)::Cvoid
end

"""
    ___tracy_emit_gpu_zone_begin_callstack(arg1)


### Prototype
```c
TRACY_API void ___tracy_emit_gpu_zone_begin_callstack( const struct ___tracy_gpu_zone_begin_callstack_data );
```
"""
function ___tracy_emit_gpu_zone_begin_callstack(arg1)
    @ccall libtracyclient.___tracy_emit_gpu_zone_begin_callstack(arg1::___tracy_gpu_zone_begin_callstack_data)::Cvoid
end

"""
    ___tracy_emit_gpu_zone_begin_alloc(arg1)


### Prototype
```c
TRACY_API void ___tracy_emit_gpu_zone_begin_alloc( const struct ___tracy_gpu_zone_begin_data );
```
"""
function ___tracy_emit_gpu_zone_begin_alloc(arg1)
    @ccall libtracyclient.___tracy_emit_gpu_zone_begin_alloc(arg1::___tracy_gpu_zone_begin_data)::Cvoid
end

"""
    ___tracy_emit_gpu_zone_begin_alloc_callstack(arg1)


### Prototype
```c
TRACY_API void ___tracy_emit_gpu_zone_begin_alloc_callstack( const struct ___tracy_gpu_zone_begin_callstack_data );
```
"""
function ___tracy_emit_gpu_zone_begin_alloc_callstack(arg1)
    @ccall libtracyclient.___tracy_emit_gpu_zone_begin_alloc_callstack(arg1::___tracy_gpu_zone_begin_callstack_data)::Cvoid
end

"""
    ___tracy_emit_gpu_zone_end(data)


### Prototype
```c
TRACY_API void ___tracy_emit_gpu_zone_end( const struct ___tracy_gpu_zone_end_data data );
```
"""
function ___tracy_emit_gpu_zone_end(data)
    @ccall libtracyclient.___tracy_emit_gpu_zone_end(data::___tracy_gpu_zone_end_data)::Cvoid
end

"""
    ___tracy_emit_gpu_time(arg1)


### Prototype
```c
TRACY_API void ___tracy_emit_gpu_time( const struct ___tracy_gpu_time_data );
```
"""
function ___tracy_emit_gpu_time(arg1)
    @ccall libtracyclient.___tracy_emit_gpu_time(arg1::___tracy_gpu_time_data)::Cvoid
end

"""
    ___tracy_emit_gpu_new_context(arg1)


### Prototype
```c
TRACY_API void ___tracy_emit_gpu_new_context( const struct ___tracy_gpu_new_context_data );
```
"""
function ___tracy_emit_gpu_new_context(arg1)
    @ccall libtracyclient.___tracy_emit_gpu_new_context(arg1::___tracy_gpu_new_context_data)::Cvoid
end

"""
    ___tracy_emit_gpu_context_name(arg1)


### Prototype
```c
TRACY_API void ___tracy_emit_gpu_context_name( const struct ___tracy_gpu_context_name_data );
```
"""
function ___tracy_emit_gpu_context_name(arg1)
    @ccall libtracyclient.___tracy_emit_gpu_context_name(arg1::___tracy_gpu_context_name_data)::Cvoid
end

"""
    ___tracy_emit_gpu_calibration(arg1)


### Prototype
```c
TRACY_API void ___tracy_emit_gpu_calibration( const struct ___tracy_gpu_calibration_data );
```
"""
function ___tracy_emit_gpu_calibration(arg1)
    @ccall libtracyclient.___tracy_emit_gpu_calibration(arg1::___tracy_gpu_calibration_data)::Cvoid
end

"""
    ___tracy_emit_gpu_zone_begin_serial(arg1)


### Prototype
```c
TRACY_API void ___tracy_emit_gpu_zone_begin_serial( const struct ___tracy_gpu_zone_begin_data );
```
"""
function ___tracy_emit_gpu_zone_begin_serial(arg1)
    @ccall libtracyclient.___tracy_emit_gpu_zone_begin_serial(arg1::___tracy_gpu_zone_begin_data)::Cvoid
end

"""
    ___tracy_emit_gpu_zone_begin_callstack_serial(arg1)


### Prototype
```c
TRACY_API void ___tracy_emit_gpu_zone_begin_callstack_serial( const struct ___tracy_gpu_zone_begin_callstack_data );
```
"""
function ___tracy_emit_gpu_zone_begin_callstack_serial(arg1)
    @ccall libtracyclient.___tracy_emit_gpu_zone_begin_callstack_serial(arg1::___tracy_gpu_zone_begin_callstack_data)::Cvoid
end

"""
    ___tracy_emit_gpu_zone_begin_alloc_serial(arg1)


### Prototype
```c
TRACY_API void ___tracy_emit_gpu_zone_begin_alloc_serial( const struct ___tracy_gpu_zone_begin_data );
```
"""
function ___tracy_emit_gpu_zone_begin_alloc_serial(arg1)
    @ccall libtracyclient.___tracy_emit_gpu_zone_begin_alloc_serial(arg1::___tracy_gpu_zone_begin_data)::Cvoid
end

"""
    ___tracy_emit_gpu_zone_begin_alloc_callstack_serial(arg1)


### Prototype
```c
TRACY_API void ___tracy_emit_gpu_zone_begin_alloc_callstack_serial( const struct ___tracy_gpu_zone_begin_callstack_data );
```
"""
function ___tracy_emit_gpu_zone_begin_alloc_callstack_serial(arg1)
    @ccall libtracyclient.___tracy_emit_gpu_zone_begin_alloc_callstack_serial(arg1::___tracy_gpu_zone_begin_callstack_data)::Cvoid
end

"""
    ___tracy_emit_gpu_zone_end_serial(data)


### Prototype
```c
TRACY_API void ___tracy_emit_gpu_zone_end_serial( const struct ___tracy_gpu_zone_end_data data );
```
"""
function ___tracy_emit_gpu_zone_end_serial(data)
    @ccall libtracyclient.___tracy_emit_gpu_zone_end_serial(data::___tracy_gpu_zone_end_data)::Cvoid
end

"""
    ___tracy_emit_gpu_time_serial(arg1)


### Prototype
```c
TRACY_API void ___tracy_emit_gpu_time_serial( const struct ___tracy_gpu_time_data );
```
"""
function ___tracy_emit_gpu_time_serial(arg1)
    @ccall libtracyclient.___tracy_emit_gpu_time_serial(arg1::___tracy_gpu_time_data)::Cvoid
end

"""
    ___tracy_emit_gpu_new_context_serial(arg1)


### Prototype
```c
TRACY_API void ___tracy_emit_gpu_new_context_serial( const struct ___tracy_gpu_new_context_data );
```
"""
function ___tracy_emit_gpu_new_context_serial(arg1)
    @ccall libtracyclient.___tracy_emit_gpu_new_context_serial(arg1::___tracy_gpu_new_context_data)::Cvoid
end

"""
    ___tracy_emit_gpu_context_name_serial(arg1)


### Prototype
```c
TRACY_API void ___tracy_emit_gpu_context_name_serial( const struct ___tracy_gpu_context_name_data );
```
"""
function ___tracy_emit_gpu_context_name_serial(arg1)
    @ccall libtracyclient.___tracy_emit_gpu_context_name_serial(arg1::___tracy_gpu_context_name_data)::Cvoid
end

"""
    ___tracy_emit_gpu_calibration_serial(arg1)


### Prototype
```c
TRACY_API void ___tracy_emit_gpu_calibration_serial( const struct ___tracy_gpu_calibration_data );
```
"""
function ___tracy_emit_gpu_calibration_serial(arg1)
    @ccall libtracyclient.___tracy_emit_gpu_calibration_serial(arg1::___tracy_gpu_calibration_data)::Cvoid
end

const TRACY_HAS_CALLSTACK = 2

# Skipping MacroDefinition: TRACY_API __attribute__ ( ( visibility ( "default" ) ) )

"""
This struct effectively inherits from ___tracy_source_location_data and extends it with several
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

end # module
