module BasicTests
    using Tracy
    using Test

    @tracepoint "test tracepoint" begin
	    println("Hello, world!")
    end

    @test_throws ErrorException @tracepoint "test exception" begin
        error("oh no!")
    end
end
