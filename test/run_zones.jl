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

@tracepoint "test tracepoint" begin
    println("Hello, world!")
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


sleep(0.5)
