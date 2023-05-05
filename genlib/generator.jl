using Clang.Generators
using TOML: TOML
using Scratch: get_scratch!
using UUIDs: UUID
using Downloads: download
using Tar: extract
using p7zip_jll

tracy_uuid = UUID(TOML.parsefile(joinpath(dirname(@__DIR__), "Project.toml"))["uuid"])

scratch_dir = get_scratch!(tracy_uuid, "tracy_releases")

# Ideally, the header files should be present in the jll
v = "0.9.1"
file = "$v.tar.gz"
tracy_vdir = joinpath(scratch_dir, v)
if !isdir(tracy_vdir)
    exe7z = p7zip_jll.p7zip()
    targz = download("https://github.com/wolfpld/tracy/archive/refs/tags/v$v.tar.gz")
    extract(`$exe7z x $targz -so`, tracy_vdir)
end

tracy_header = joinpath(tracy_vdir, "tracy-$v", "public", "tracy", "TracyC.h")

headers = [tracy_header]

options = load_options(joinpath(@__DIR__, "generator.toml"))
options["general"]["library_name"] = "libtracyclient"
options["general"]["module_name"] = "LibTracyClient"
options["general"]["prologue_file_path"] = "./prologue.jl"
options["general"]["epilogue_file_path"] = "./epilogue.jl"
options["general"]["output_file_path"] = joinpath(@__DIR__, "..", "src", "LibTracyClient.jl")
options["general"]["output_ignorelist"] = ["TracyFunction", "TracyFile", "TracyLine", "TracyCFrameMark", "TracyCIsConnected"]

args = get_default_args()
push!(args, "-fparse-all-comments")
push!(args, "-DTRACY_ENABLE")

ctx = create_context(headers, args, options)

build!(ctx)
