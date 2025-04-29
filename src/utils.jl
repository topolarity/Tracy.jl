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
    capture(outfile::String; port::Integer = 9001)
    gui(; port::Integer = 9001)

Starts a Tracy capture agent running in the background.  Returns the `Cmd` object for use
with `wait()`.  Note that if you are using a tracy-enabled build of Julia, you will need
to ensure that the capture agent is running before the Julia executable starts, otherwise
the capture agent may not see the beginning of every zone, which it considers to be a
fatal error.

The recommended methodology for usage of this function is something similar to:

```julia
port = 9000 + rand(1:1000)
p = Tracy.capture("my_workload.tracy"; port)
run(addenv(`\$(Base.julia_cmd()) workload.jl`,
           "TRACY_PORT" => string(port),
           "JULIA_WAIT_FOR_TRACY" => "1"))
wait(p)
```

!!! note
    This command is only available if you also load `TracyProfiler_jll`.
"""
capture(outfile::String; kwargs...) = _capture(outfile, :dummy; kwargs...)
_capture(outfile::String, dummy; kwargs...) = error("TracyProfiler_jll not loaded")

gui(;kwargs...) = _gui(:dummy; kwargs...)
_gui(dummy; kwargs...) = error("TracyProfiler_jll not loaded")
