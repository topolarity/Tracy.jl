using Test, Tracy

const connect_tracy_capture = true
const connect_tracy_gui = false # useful for manually inspecting the output
const verify_csv_output = sizeof(Int) == 8 && !Sys.iswindows() && !connect_tracy_gui
const tracy_port = 9001

const run_zones_path = joinpath(@__DIR__, "run_zones.jl")
const test_pkg_path = joinpath(@__DIR__, "TestPkg", "src", "TestPkg.jl")

# Build map of `@tracepoint` names to line number:
function parse_tracepoint_lines!(zone_lines::Dict{String,String}, file::AbstractString)
    lines = split(String(read(file)), "\n")
    for (idx, line) in enumerate(lines)
        m = match(r"@tracepoint\s+\"([^\"]+)\"", line)
        if m !== nothing
            zone_lines[string(m.captures[1])] = string(idx)
        end
    end
end

const zone_lines = Dict{String,String}()
parse_tracepoint_lines!(zone_lines, run_zones_path)
parse_tracepoint_lines!(zone_lines, test_pkg_path)

if !connect_tracy_capture && !connect_tracy_gui
    include(run_zones_path)
else
    # Spawn the headless tracy profiler, run the test script, and export the results to a CSV
    using TracyProfiler_jll
    tmp = mktempdir(; cleanup=false)#  mktempdir()
    tracyfile = joinpath(tmp, "tracyjltest.tracy")


    if connect_tracy_gui
        p = Tracy.gui(; port=tracy_port)
    else
        p = Tracy.capture(tracyfile; port=tracy_port)
    end
    code = "include($(repr(run_zones_path)))"

    run(addenv(`$(Base.julia_cmd()) --project=$(dirname(Base.active_project())) -e $code`,
               "TRACYJL_WAIT_FOR_TRACY"=>1, "TRACY_PORT" => string(tracy_port)))
    wait(p)

    if !verify_csv_output
        @warn "Not running CSV export test on 32-bit system or Windows"
    else
        csvfile = joinpath(tmp, "tracyjltest.csv")
        run(pipeline(`$(TracyProfiler_jll.csvexport()) $tracyfile`, stdout=csvfile))

        # Parse the CSV file
        zones = []
        open(csvfile) do io
            header = readline(io) # header
            colnames = Symbol.(split(header, ','))
            while !eof(io)
                fields = split(readline(io), ',')
                nt = (; zip(colnames, fields)...)
                push!(zones, nt)
            end
        end

        all_names_recorded = Set([z.name for z in zones])
        all_names_expected = Set(["has_return_type_annotation", "has_no_arguments", "test tracepoint", "test exception", "timing", "zone f", "g", "hxT", "kwargs_func",
                                  "<anon>", "SLP", "SROA", "Inlining", "rainbow outer", "rainbow inner",
                                  "conditionally disabled"])
        @test all_names_recorded == all_names_expected

        @testset "check zone data" begin
            for zone in zones
                if zone.name == "test tracepoint"
                    @test Base.samefile(zone.src_file, joinpath(@__DIR__, "run_zones.jl"))
                    @test zone.counts == "3"
                    @test zone.src_line == zone_lines[zone.name]
                elseif zone.name == "test exception"
                    @test zone.counts == "5"
                    @test zone.src_line == zone_lines[zone.name]
                elseif zone.name == "timing"
                    @test Base.samefile(zone.src_file, joinpath(@__DIR__, "TestPkg", "src", "TestPkg.jl"))
                    @test zone.counts == "100"
                    @test zone.src_line == zone_lines[zone.name]
                elseif zone.name == "zone f"
                    @test Base.samefile(zone.src_file, joinpath(@__DIR__, "run_zones.jl"))
                    @test zone.counts == "10"
                elseif zone.name == "g"
                    @test zone.counts == "20"
                    # This one isn't given via a `@tracepoint`,
                    # so it's a little tougher to check that its source
                    # line is correct, especially since we don't even have
                    # the `g()` function object to ask the lineinfo from.
                elseif zone.name == "kwargs_func"
                    @test zone.counts == "20"
                elseif zone.name == "hxT"
                    @test zone.counts == "30"
                    @test zone.src_line == zone_lines[zone.name]
                elseif zone.name == "<anon>"
                    @test zone.counts == "40"
                elseif zone.name == "SLP"
                    @test zone.counts == "5"
                    @test zone.src_line == zone_lines[zone.name]
                elseif zone.name == "SROA"
                    @test zone.counts == "10"
                    @test zone.src_line == zone_lines[zone.name]
                elseif zone.name == "Inlining"
                    @test zone.counts == "15"
                    @test zone.src_line == zone_lines[zone.name]
                elseif zone.name == "rainbow outer"
                elseif zone.name == "rainbow inner"
                elseif zone.name == "has_no_arguments"
                elseif zone.name == "has_return_type_annotation"
                elseif zone.name == "conditionally disabled"
                    @test zone.counts == "5"
                else
                    error("unknown zone.name = $(zone.name)")
                end
            end
        end
    end
end
