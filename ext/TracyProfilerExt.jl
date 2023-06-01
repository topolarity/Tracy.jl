module TracyProfilerExt

using Tracy, TracyProfiler_jll

function Tracy._capture(outfile::String, dummy::Symbol; port::Integer = 9001)
    run(`$(TracyProfiler_jll.capture()) -p $(port) -o $(outfile) -f`; wait=false)
end

function Tracy._gui(dummy::Symbol; port::Integer = 9001)
    run(`$(TracyProfiler_jll.tracy()) -a 127.0.0.1 -p $(port)`; wait=false)
end

end # module
