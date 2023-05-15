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

function _tracycolor(num::Integer)
    @assert 0 <= num <= 0xFFFFFF
    return num
end
