module BasicTests
    using Tracy
    using Test

    @zone "test zone" begin
	    println("Hello, world!")
    end

    @test_throws ErrorException @zone "test exception" begin
        error("oh no!")
    end
end
