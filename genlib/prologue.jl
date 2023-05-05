using LibTracyClient_jll: libTracyClient
using Libdl: dllist, dlopen

const BASE_TRACY_LIB = let
    base_tracy_libs = filter(contains("libTracyClient"), dllist())
    isempty(base_tracy_libs) ? nothing : first(base_tracy_libs)
end
libtracyclient::String = ""

function __init__()
    global libtracyclient = something(BASE_TRACY_LIB, libTracyClient)
end
