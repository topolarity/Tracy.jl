var documenterSearchIndex = {"docs":
[{"location":"#Tracy.jl","page":"Tracy.jl","title":"Tracy.jl","text":"","category":"section"},{"location":"","page":"Tracy.jl","title":"Tracy.jl","text":"A flexible profiling tool for tracing Julia code, LLVM compilation, Garbage Collection, and more.","category":"page"},{"location":"","page":"Tracy.jl","title":"Tracy.jl","text":"@tracepoint\ntracymsg\nTracy.@register_tracepoints\nTracy.enable_tracepoint\nTracy.configure_tracepoint","category":"page"},{"location":"#Tracy.@tracepoint","page":"Tracy.jl","title":"Tracy.@tracepoint","text":"Tracing Julia code\n\nCode you'd like to trace should be wrapped with @tracepoint\n\n@tracepoint \"name\" <expression>\n\nTypically the expression will be a begin-end block:\n\n@tracepoint \"data aggregation\" begin\n    # lots of compute here...\nend\n\nThe name of the tracepoint must be a literal string, and it cannot be changed at runtime.\n\nIf you don't have Tracy installed, you can install TracyProfiler_jll and start it with run(TracyProfiler_jll.tracy(); wait=false).\n\njulia> x = rand(10,10);\n\njulia> @tracepoint \"multiply\" x * x;\n\n\n\n\n\n","category":"macro"},{"location":"#Tracy.tracymsg","page":"Tracy.jl","title":"Tracy.tracymsg","text":"tracymsg(msg::AbstractString; color::Union{Integer,Symbol,NTuple{3, Integer}, Nothing}=nothing, callstack_depth::Integer=0)\n\nSend a message to Tracy that gets shown in the \"Message\" window. If color is nothing, the default color is used. Otherwise, the color argument can be given as:\n\nAn integer: The hex code of the color as 0xRRGGBB.\nA symbol: Can take the value :black, :blue, :green, :cyan, :red, :magenta, :yellow, :white, :light_black, :light_blue, :light_green, :light_cyan, :light_red, :light_magenta, :light_yellow, :light_white.\nA tuple of three integers: The RGB value (R, G, B) where each value is in the range 0..255.\n\nThe callstack_depth argument determines the depth of the callstack that is collected.\n\n\n\n\n\n","category":"function"},{"location":"#Tracy.@register_tracepoints","page":"Tracy.jl","title":"Tracy.@register_tracepoints","text":"Register this module's @tracepoint callsites with Tracy.jl\n\nThis will allow tracepoints to appear in Tracy's Enable/Disable window, even if they haven't been run yet. Using this macro is optional, but it's recommended to call it from within your module's __init__ method.\n\n\n\n\n\n","category":"macro"},{"location":"#Tracy.enable_tracepoint","page":"Tracy.jl","title":"Tracy.enable_tracepoint","text":"enable_tracepoint\n\nEnable/disable a set of tracepoint(s) in the provided modules, based on whether they match the filters provided for name/func/file.\n\n\n\n\n\n","category":"function"},{"location":"#Tracy.configure_tracepoint","page":"Tracy.jl","title":"Tracy.configure_tracepoint","text":"configure_tracepoint\n\nEnable/disable a set of tracepoint(s) in the provided modules by invalidating any existing code containing the tracepoint(s).\n\nwarning: Warning\nThis invalidates the code generated for all functions containing the selected zones.This will trigger re-compilation for these functions and may cause undesirable latency. It is strongly recommended to use enable_tracepoint instead.\n\n\n\n\n\n","category":"function"}]
}
