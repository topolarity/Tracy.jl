"""
    tracyplot_config(name::String; format::Symbol=:number, step::Bool=false, fill::Bool=true, color::Union{Integer,Symbol,NTuple{3, Integer}, Nothing}=nothing)

Configures a plot with the given name. Should typically be called once per plot.

- The `format` parameter can be one of `:number`, `:memory`, or `:percentage`.
- The `step` parameter determines whether the plot will be displayed as a staircase or will smoothly change between plot points
- The `fill` parameter can be used to disable filling the area below the plot with a solid color.

If `color` is `nothing`, the default color is used.
Otherwise, the `color` argument can be given as:
- An integer: The hex code of the color as `0xRRGGBB`.
- A symbol: Can take the value `:black`, `:blue`, `:green`, `:cyan`, `:red`, `:magenta`, `:yellow`, `:white`,
  `:light_black`, `:light_blue`, `:light_green`, `:light_cyan`, `:light_red`, `:light_magenta`, `:light_yellow`, `:light_white`.
- A tuple of three integers: The RGB value `(R, G, B)` where each value is in the range 0..255.

See also: [`tracyplot`](@ref).
"""
function tracyplot_config(name::String; format::Symbol=:number, step::Bool=false, fill::Bool=true, color::Union{Integer,Symbol,NTuple{3, Integer}, Nothing}=nothing)
    tracyformat = format == :number     ? 0 :
                  format == :memory     ? 1 :
                  format == :percentage ? 2 :
                  error("Invalid format: $(repr(format)), must be one of :number, :memory, or :percentage")
    @ccall libtracy.___tracy_emit_plot_config(name::Cstring, tracyformat::Cint, step::Cint, fill::Cint, _tracycolor(color)::UInt32)::Cvoid
end

"""
    tracyplot(name::String, value::Number)

Plots the given `value` on the plot with the given `name`.

See also: [`tracyplot_config`](@ref).
"""
function tracyplot(name::String, v::Number)
    if v isa Integer
        @ccall libtracy.___tracy_emit_plot_int(name::Cstring, v::Cint)::Cvoid
    elseif v isa Float32
        @ccall libtracy.___tracy_emit_plot_float(name::Cstring, v::Cfloat)::Cvoid
    else
        @ccall libtracy.___tracy_emit_plot(name::Cstring, v::Cdouble)::Cvoid
    end
end
