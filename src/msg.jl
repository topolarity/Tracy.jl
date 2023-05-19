"""
    tracymsg(msg::AbstractString; color::Union{Integer,Symbol,NTuple{3, Integer}, Nothing}=nothing, callstack_depth::Integer=0)

Send a message to Tracy that gets shown in the "Message" window.
If `color` is `nothing`, the default color is used.
Otherwise, the `color` argument can be given as:
$color_docstr

The `callstack_depth` argument determines the depth of the callstack that is collected.
"""
function tracymsg(msg::AbstractString; color::Union{Integer,Symbol,NTuple{3,Integer},Nothing}=nothing, callstack_depth::Integer=0)
    if color === nothing
        @ccall libtracy.___tracy_emit_message(msg::Cstring, length(msg)::Csize_t, callstack_depth::Cint)::Cvoid
    else
        @ccall libtracy.___tracy_emit_messageC(msg::Cstring, length(msg)::Csize_t, _tracycolor(color)::UInt32, callstack_depth::Cint)::Cvoid
    end
end
