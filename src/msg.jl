"""
    tracymsg(msg::AbstractString; color::Union{Number,Symbol,NTuple{3, Integer}, Nothing}=nothing, callstack::Bool)

Send a message to Tracy that gets shown in the "Message" window.
If `color` is `nothing`, the default color is used.
Otherwise, the `color` argument can be given as:
- An unsigned integer: The hex code of the color as `0xRRGGBB`.
- A symbol or a signed integer: Same meaning as the color argument in `printstyled`.
- A tuple of three integers: The RGB value `(R, G, B)` where each value is in the range 0..255.

The `callstack` argument determines whether a callstack is collected
"""
function tracymsg(msg::AbstractString; color::Union{Number,Integer,Symbol,NTuple{3,Integer},Nothing}=nothing, callstack::Bool=false)
    if color === nothing
        @ccall libtracy.___tracy_emit_message(msg::Cstring, length(msg)::Csize_t, callstack::Cint)::Cvoid
    else
        @ccall libtracy.___tracy_emit_messageC(msg::Cstring, length(msg)::Csize_t, _tracycolor(color)::UInt32, callstack::Cint)::Cvoid
    end
end
