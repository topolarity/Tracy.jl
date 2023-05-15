module BasicTests
    using Tracy
    using Test
    using Pkg

    @tracepoint "test tracepoint" begin
	    println("Hello, world!")
    end

    @test_throws ErrorException @tracepoint "test exception" begin
        error("oh no!")
    end

    Pkg.activate("TestPkg")
    Pkg.develop(; path = joinpath(@__DIR__, ".."))
    # Test that a precompiled package also works,
    # Can also be manually verified by attaching Tracy to this process
    # withenv("JULIA_WAIT_FOR_TRACY"=>"1", "TRACY_PORT"=>"9000") do
        run(`$(Base.julia_cmd()) --project="TestPkg" -e 'using TestPkg; TestPkg.time_something(); TestPkg.test_data()'`)
    # end
end
