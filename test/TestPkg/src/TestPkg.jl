module TestPkg

using Tracy

function time_something()
    for _ in 1:100
        @tracepoint "timing" rand(100)
    end
end

function test_data()
    tracymeta = only(Tracy.tracymeta(@__MODULE__))
    @assert unsafe_string(tracymeta.zone_name) == "timing"
    @assert unsafe_string(tracymeta.function_name) == Tracy.unknown_string
    @assert unsafe_string(tracymeta.file) == @__FILE__
    @assert tracymeta.line == 7
    @assert unsafe_string(tracymeta.module_name) == "TestPkg"
end

end # module TestPkg
