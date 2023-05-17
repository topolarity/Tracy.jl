using Test

const verify_tracy_output = true
const connect_tracy_gui = false # useful for manually inspecting the output


const run_zone_path = joinpath(@__DIR__, "run_zones.jl")
if !verify_tracy_output && !connect_tracy_gui
    include(run_zone_path)
else
    # Spawn the headless tracy profiler, run the test script, and export the results to a CSV
    using TracyProfiler_jll
    tmp = mktempdir()
    tracyfile = joinpath(tmp, "tracyjltest.tracy")
    if connect_tracy_gui
        p = run(`$(TracyProfiler_jll.tracy()) -a 127.0.0.1 -p 9001`; wait=false)
    else
        p = run(`$(TracyProfiler_jll.capture()) -p 9001 -o $tracyfile -f`; wait=false)
    end

    withenv("TRACYJL_WAIT_FOR_TRACY"=>1, "TRACY_PORT" => 9001) do
        code = "include(\"$run_zone_path\")"
        run(`$(Base.julia_cmd()) --project=$(Base.active_project()) -e $code`)
    end
    wait(p)

    if !connect_tracy_gui
        csvfile = joinpath(tmp, "tracyjltest.csv")
        run(pipeline(`$(TracyProfiler_jll.csvexport()) $(repr(tracyfile))`, stdout=csvfile))

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

        @testset "check zone data" begin
            for zone in zones
                if zone.name == "test tracepoint"
                    @test Base.samefile(zone.src_file, joinpath(@__DIR__, "run_zones.jl"))
                    @test zone.counts == "1"
                    @test zone.src_line == "16"
                elseif zone.name == "text exception"
                    @test zone.counts == "5"
                    @test zone.src_line == "22"
                elseif zone.name == "timing"
                    @test Base.samefile(zone.src_file, joinpath(@__DIR__, "TestPkg", "src", "TestPkg.jl"))
                    @test zone.counts == "100"
                    @test zone.src_line == "7"
                end
            end
        end
    end
end
