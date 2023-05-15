function _tracycolor((r,g,b)::Tuple{Integer, Integer, Integer})
    @assert 0 <= r <= 255
    @assert 0 <= g <= 255
    @assert 0 <= b <= 255
    return UInt32((r << 16) | (g << 8) | b)
end


# We are using the updated colorscheme from the Windows 10 console:
# https://devblogs.microsoft.com/commandline/updating-the-windows-console-colors/
# The symbol names are the same as for `printstyled`.
function _tracycolor(sym::Symbol)
    sym == :black         ? _tracycolor((12 , 12 , 12 )) :
    sym == :blue          ? _tracycolor((0  , 55 , 218)) :
    sym == :green         ? _tracycolor((19 , 161, 14 )) :
    sym == :cyan          ? _tracycolor((58 , 150, 221)) :
    sym == :red           ? _tracycolor((197, 15 , 31 )) :
    sym == :magenta       ? _tracycolor((136, 23 , 152)) :
    sym == :yellow        ? _tracycolor((193, 156, 0  )) :
    sym == :white         ? _tracycolor((204, 204, 204)) :
    sym == :light_black   ? _tracycolor((118, 118, 118)) :
    sym == :light_blue    ? _tracycolor((59 , 120, 255)) :
    sym == :light_green   ? _tracycolor((22 , 198, 12 )) :
    sym == :light_cyan    ? _tracycolor((97 , 214, 214)) :
    sym == :light_red     ? _tracycolor((231, 72 , 86 )) :
    sym == :light_magenta ? _tracycolor((180, 0  , 158)) :
    sym == :light_yellow  ? _tracycolor((249, 241, 165)) :
    sym == :light_white   ? _tracycolor((242, 242, 242)) :
    error("Unknown color: $sym")
end

function system_colors(num)
    num == 0  ? _tracycolor(:black) :
    num == 1  ? _tracycolor(:light_red) :
    num == 2  ? _tracycolor(:light_green) :
    num == 3  ? _tracycolor(:light_yellow) :
    num == 4  ? _tracycolor(:light_blue) :
    num == 5  ? _tracycolor(:light_magenta) :
    num == 6  ? _tracycolor(:light_cyan) :
    num == 7  ? _tracycolor(:light_white) :
    num == 8  ? _tracycolor(:light_black) :
    num == 9  ? _tracycolor(:red) :
    num == 10 ? _tracycolor(:green) :
    num == 11 ? _tracycolor(:yellow) :
    num == 12 ? _tracycolor(:blue) :
    num == 13 ? _tracycolor(:magenta) :
    num == 14 ? _tracycolor(:cyan) :
    num == 15 ? _tracycolor(:white) :
    error("Unknown color: $num")
end

function scale_value(val)
    return val == 0 ? 0 : 95 + 40 * (val - 1)
end

function _tracycolor(num::Integer)
    if num isa Unsigned
        @assert 0 <= num <= 0xFFFFFF
        return num
    else
        # Converts from the 256 ANSI color palette to 24-bit RGB.
        @assert 0 <= num <= 255
        if num < 16
            # system colors
            return system_colors(num)
        elseif num < 232
            # color cube
            num -= 16
            b = num % 6
            num = div(num, 6)
            g = num % 6
            r = div(num, 6)
            return UInt32((scale_value(r) << 16) + (scale_value(g) << 8) + scale_value(b))
        else
            # grayscale ramp
            c = 8 + (num - 232) * 10
            return UInt32((c << 16) + (c << 8) + c)
        end
    end
end
