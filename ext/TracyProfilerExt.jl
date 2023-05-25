module TracyProfilerExt

using Tracy, TracyProfiler_jll

function Tracy._capture(outfile::String, dummy::Symbol; gui::Bool = false, port::Int64 = 9001)
    if gui
        run(`$(TracyProfiler_jll.tracy()) -a 127.0.0.1 -p $(port)`; wait=false)
    else
        run(`$(TracyProfiler_jll.capture()) -p $(port) -o $(outfile) -f`; wait=false)
    end
end

end # module
