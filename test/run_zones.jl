using Tracy
using Test
using Pkg

# The line numbers in this file are relevant. If you change them, you must also
# update the lines in `runtests.jl` that check the output.

if haskey(ENV, "TRACYJL_WAIT_FOR_TRACY")
    @info "Waiting for tracy to connect..."
    while (@ccall Tracy.libtracy.___tracy_connected()::Cint) == 0
        sleep(0.01)
    end
    @info "Connected!"
end

for i in 1:3
    @tracepoint "test tracepoint" begin
        println("Hello, world!")
    end
end

for i in 1:5
    @test_throws ErrorException @tracepoint "test exception" begin
        error("oh no!")
    end
end

Pkg.develop(; path = joinpath(@__DIR__, "TestPkg"), io=devnull)
# Test that a precompiled package also works,
using TestPkg
TestPkg.time_something()
TestPkg.test_data()

@testset "msg" begin
    tracymsg(SubString("Hello, world!"); color=0xFF00FF)
    tracymsg(SubString("Hello, sailor!"); color=:red)

    steps = 0:30:255
    for r = steps
        for g=steps
            for b=steps
                tracymsg("rgb color ($r, $g, $b)"; color=(r,g,b), callstack_depth=rand(1:5))
            end
            tracymsg("")
        end
        tracymsg("")
    end

    tracymsg("")
    tracymsg("system color red"; color=:red)
    tracymsg("system color green"; color=:green)
    tracymsg("system color blue"; color=:blue)
    tracymsg("system color yellow"; color=:yellow)
    tracymsg("system color magenta"; color=:magenta)
end

function check_stacktrace(function_name::Union{Symbol, Nothing}, filepath::AbstractString, line::Int)
    trace = stacktrace()[2:end]

    # Verify that the first stack frame is correct
    caller = trace[1]
    !isnothing(function_name) && @test caller.func == function_name
    @test caller.file == Symbol(filepath)
    @test caller.line == line

    # And that no stack frame includes the actual macro source
    for stackframe in trace
        @test !contains(string(stackframe.file), "Tracy.jl/src")
    end
end

# Various ways to trace a function
@tracepoint "zone f" f(x) = (check_stacktrace(nothing, @__FILE__(), @__LINE__()); x^2)
foreach(n -> f(n), 1:10)
@tracepoint function g(x)
    x^2
end
foreach(n -> g(n), 1:20)
@tracepoint "hxT" function h(x::T) where {T}
    T(x^2)
end
foreach(n -> h(n), 1:30)
i = @tracepoint x->(check_stacktrace(nothing, @__FILE__(), @__LINE__()); x^2)
foreach(n -> i(n), 1:40)

tracyplot_config("sin"; fill=false, color=0xFF00FF)
tracyplot_config("cos"; format=:percentage, step=true, fill=true, color=0x0000FF)

for x in range(0, 2pi, 100)
    tracyplot("sin", sin(x))
    tracyplot("cos", 100*cos(x))
    sleep(0.005)
end

sleep(0.5)
