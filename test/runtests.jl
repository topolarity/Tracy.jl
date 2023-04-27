module BasicTests
    using Tracy

    @tracepoint "test tracepoint" begin
	println("Hello, world!")
    end
end
