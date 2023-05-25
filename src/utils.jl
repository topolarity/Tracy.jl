function extract_keywords(ex0)
    kws = Dict{Symbol, Any}()
    arg = ex0[end]
    for i in 1:length(ex0)-1
        x = ex0[i]
        if x isa Expr && x.head === :(=) # Keyword given of the form "foo=bar"
            if length(x.args) != 2
               error("Invalid keyword argument: $x")
            end
            kws[x.args[1]] = x.args[2]
        else
            return error("@tracepoint expects only one non-keyword argument")
        end
    end
    return kws, arg
end

"""
    wait_for_tracy(;timeout::Float64 = 20.0)

Waits up to `timeout` seconds for `libtracy` to connect to a listening capture
agent.  If a timeout occurs, throws an `InvalidStateException`.
"""
function wait_for_tracy(;timeout::Float64 = 20.0)
    t_start = time()
    while (time() - t_start) < timeout
        if (@ccall libtracy.___tracy_connected()::Cint) == 1
            return
        end
        sleep(0.01)
    end
    throw(InvalidStateException("Could not connect to tracy client", :timeout))
end

"""
    capture(outfile::String; gui::Bool = false, port::Int64 = 9001)

Starts a Tracy capture agent running in the background.  Returns the `Cmd` object for use
with `wait()`.

!!! note
    This command is only available if you also load `TracyProfiler_jll`.
"""
capture(outfile::String; kwargs...) = _capture(outfile, :dummy; kwargs...)
_capture(outfile::String, dummy) = error("TracyProfiler_jll not loaded")
