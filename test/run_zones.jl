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

colors = [0x00FF00, (30, 60, 90), :yellow]
names = ["SLP", "SROA", "inlining"]
text = ["ok", 0, "bad"]
for i in 1:3
    @tracepoint "optimizations" color=colors[i] name2=names[i] text=text[i] begin
        sleep(0.1)
    end
end

sleep(0.5)
