module TestPkg

using Tracy

function time_something()
    for _ in 1:100
        @tracepoint "timing" rand(100)
    end
end

function test_data()
    meta = only(Tracy.meta(@__MODULE__))
    @assert unsafe_string(meta.zone_name) == "timing"
    @assert unsafe_string(meta.function_name) == Tracy.unknown_string
    @assert unsafe_string(meta.file) == @__FILE__
    @assert meta.line == 7
    @assert unsafe_string(meta.module_name) == "TestPkg"
end

end # module TestPkg
