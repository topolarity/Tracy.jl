using Tracy
using Test
using Pkg

# The line numbers in this file are relevant. If you change them, you must also
# update the lines in `runtests.jl` that check the output.

if haskey(ENV, "TRACYJL_WAIT_FOR_TRACY")
    @info "Waiting for tracy to connect..."
    wait_for_tracy()
    @info "Connected!"
end

@tracepoint function has_no_arguments() end
has_no_arguments()

struct NotDefinedInsideTracy end
@tracepoint has_return_type_annotation()::NotDefinedInsideTracy = NotDefinedInsideTracy()
has_return_type_annotation()

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
@tracepoint "kwargs_func" function j(x; pow=2)
    x^pow
end
foreach(n -> j(n; pow=3), 1:20)

tracyplot_config("sin"; fill=false, color=0xFF00FF)
tracyplot_config("cos"; format=:percentage, step=true, fill=true, color=0x0000FF)

for x in range(0, 2pi, 100)
    tracyplot("sin", sin(x))
    tracyplot("cos", 100*cos(x))
    sleep(0.005)
end

for j in 1:5
    @tracepoint "SLP" color=0x00FF00 begin
        sleep(0.01)
    end
end
for j in 1:10
    @tracepoint "SROA" color=(10, 20, 30) begin
        sleep(0.01)
    end
end
for j in 1:15
    @tracepoint "Inlining" color=:red begin
        sleep(0.01)
    end
end

function hsv_to_rgb(h, s, v)
    h = h / 60
    i = floor(h)
    f = h - i
    p = v * (1 - s)
    q = v * (1 - s * f)
    t = v * (1 - s * (1 - f))

    if i == 0
        r, g, b = v, t, p
    elseif i == 1
        r, g, b = q, v, p
    elseif i == 2
        r, g, b = p, v, t
    elseif i == 3
        r, g, b = p, q, v
    elseif i == 4
        r, g, b = t, p, v
    else
        r, g, b = v, p, q
    end

    r, g, b = round(Int, r * 255), round(Int, g * 255), round(Int, b * 255)

    return (r, g, b)
end

function generate_rainbow(n)
    return [hsv_to_rgb(i * 360 / n, 1, 1) for i in 0:(n-1)]
end

n_outer = 50
n_inner = 10

for color in generate_rainbow(n_outer)
    @tracepoint "rainbow outer" begin
        set_zone_name!(string(color))
        set_zone_color!(color)
        for color in  generate_rainbow(n_inner)
            @tracepoint "rainbow inner" begin
                set_zone_name!(string(color))
                set_zone_color!(color)
                sleep(0.1 / (n_inner * n_outer))
            end
        end
    end
end

for i in 1:10
    @tracepoint "conditionally disabled" enabled=isodd(i) begin
        sleep(0.01)
    end
end

sleep(0.5)
