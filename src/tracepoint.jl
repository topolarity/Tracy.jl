# This file is a part of Tracy.jl. License is MIT: See LICENSE.md

_is_func_def(ex) = Meta.isexpr(ex, :function) || Base.is_short_function_def(ex) || Meta.isexpr(ex, :->)

function _extract_color(ex)
    kws, body = extract_keywords(ex)
    for (k, v) in kws
        k === :color || continue
        color = v
        if color !== 0
            if color isa Integer
                color = _tracycolor(color)
            elseif color isa QuoteNode
                color = _tracycolor(color.value)
            elseif Meta.isexpr(color, :tuple)
                if length(color.args) == 3 && all(isa.(color.args, Integer))
                    color = _tracycolor(Tuple(color.args))
                else
                    error("Invalid color tuple: $color")
                end
            else
                error("Invalid color: $color")
            end
        end
        kws[k] = color
    end
    return body, kws
end

##################
# Public methods #
##################

"""
    @tracepoint "name" color=<color> <expression>

Code you'd like to trace should be wrapped with `@tracepoint`

```julia
@tracepoint "name" <expression>
```

Typically the expression will be a `begin-end` block:

```julia
@tracepoint "data aggregation" begin
    # lots of compute here...
end
```

The name of the tracepoint must be a literal string, and it cannot
be changed at runtime.

The (default) color of the zone can be configured
with the `color` keyword argument to the macro which should be a literal that can either be:
$color_docstr

You can also trace function definitions where name of the tracepoint
will be the name of the function unless it is explicitly provided:

```julia
@tracepoint function f(x)
    x^2
end

@tracepoint "calling g" g(x) = x^2

h = @tracepoint x -> x^2
```

If you don't have Tracy installed, you can install `TracyProfiler_jll`
and start it with `run(TracyProfiler_jll.tracy(); wait=false)`.

```jldoctest
julia> x = rand(10,10);

julia> @tracepoint "multiply" x * x;

julia> @tracepoint "pow2" color=:green x^2 # green

julia> @tracepoint "pow3" color=:0xFF0000 x^3 # red

julia> @tracepoint "pow4" color=(255, 165, 0) x^4 # orange
```

If you don't have Tracy installed, you can install `TracyProfiler_jll`
and start it with `run(TracyProfiler_jll.tracy(); wait=false)`.
"""
macro tracepoint(name::String, ex...)
    body, kws = _extract_color(ex)
    if _is_func_def(body)
        return _tracepoint_func(name, body, __module__, __source__; kws...)
    else
        return _tracepoint(name, nothing, body, __module__, __source__; kws...)
    end
end

macro tracepoint(ex...)
    body, kws = _extract_color(ex)
    if _is_func_def(body)
        return _tracepoint_func(nothing, body, __module__, __source__; kws...)
    else
        error("expected a zone name for @tracepoint")
    end
end

function _tracepoint_func(name::Union{String, Nothing}, ex::Expr, mod::Module, source::LineNumberNode; kws...)
    def = splitdef(ex)
    if haskey(def, :name)
        function_name = def[:name]
        def[:name] = esc(def[:name])
    else
        function_name = :var"<anon>"
    end
    def[:args] = map(esc, def[:args])
    if haskey(def, :whereparams)
        def[:whereparams] = map(esc, def[:whereparams])
    end
    def[:body] = _tracepoint(name, string(function_name), def[:body], mod, source; kws...)
    cdef = combinedef(def)
    # Replace function definition line number node with that from source
    @assert def[:body].args[1] isa LineNumberNode
    def[:body].args[1] = source
    return cdef
end

root_module(m::Module) = parentmodule(m) === m ? m : root_module(parentmodule(m))


# Example (Local)Preferences.toml:
#
# [MyPkg.Tracy]
# enabled = true
# whitelist = ['foo', 'bar.*']
# blacklist = []
function get_preferences(mod::Module)
    root_mod = root_module(mod)
    default_prefs = Dict{String,Any}()
    if pathof(root_mod) !== nothing

        # Load default Tracy preferences from the Preferences.toml for this project
        root_dir = dirname(dirname(pathof(root_mod)))
        preferences_toml_path = joinpath(root_dir, "Preferences.toml")

        if isfile(preferences_toml_path)

            # Technically by loading Preferences.toml ourselves we are bypassing the
            # compile-time dependency tracking in Base, but the important behavior we
            # care about is for top-level overrides to trigger pre-compilation of
            # relevant dependencies, which does work.
            #
            # This does mean that you might have to `touch` source files locally to
            # re-trigger pre-compilation if you are using Preferences.toml instead of
            # LocalPreferences.toml

            toml_dict = try Base.parsed_toml(preferences_toml_path) catch e
                @warn "Failed to load Preferences.toml for $root_mod: $e"
                Dict{String, Any}()
            end
            toml_dict = get(toml_dict, string(nameof(root_mod)), Dict{String, Any}())
            default_prefs = get(toml_dict, "Tracy", Dict{String, Any}())
        end
    end

    # Apply overrides from the top-level Preferences environment
    # (typically a LocalPreferences.toml in the current project)

    toplevel_prefs = try
        load_preference(mod, "Tracy", Dict{String,Any}())
    catch e
        if !isa(e, ArgumentError)
            rethrow(e)
        end
        Dict{String, Any}()
    end

    return Base.recursive_prefs_merge(default_prefs, toplevel_prefs)
end

function _tracepoint(name::Union{String, Nothing}, func::Union{String, Nothing}, ex::Expr, mod::Module, source::LineNumberNode; color::Union{Integer,Symbol,NTuple{3,Integer}}=0)
    filepath = string(source.file)
    line = source.line

    prefs = get_preferences(mod)
    (get(prefs, "enabled", true) !== true) && return esc(ex) # No-op

    whitelist = get(prefs, "whitelist", String[".*"])
    blacklist = get(prefs, "blacklist", String[])

    filter_name = ""
    func !== nothing && (filter_name = func;)
    name !== nothing && (filter_name = name;)

    in_whitelist = mapreduce(pattern -> contains(filter_name, Regex(pattern)),
                             Base.:(|), whitelist; init=false)
    in_blacklist = mapreduce(pattern -> contains(filter_name, Regex(pattern)),
                             Base.:(|), blacklist; init=false)
    (!in_whitelist || in_blacklist) && return esc(ex) # No-op

    srcloc = TracySrcLoc(name, func, filepath, line, color, mod, true)
    push!(meta(mod), srcloc)

    return quote
        if $srcloc.file == C_NULL
            initialize!($srcloc)
        end
        local ctx = @ccall libtracy.___tracy_emit_zone_begin(pointer_from_objref($srcloc)::Ptr{Cvoid},
                                                             $srcloc.enabled::Cint)::TracyZoneContext
        $(Expr(:tryfinally,
            :($(esc(ex))),
            quote
                @ccall libtracy.___tracy_emit_zone_end(ctx::TracyZoneContext)::Cvoid
            end
        ))
    end
end

"""
    enable_tracepoint

Enable/disable a set of tracepoint(s) in the provided modules, based on whether they
match the filters provided for `name`/`func`/`file`.
"""
function enable_tracepoint(m::Module, enable::Bool; name="", func="", file="")
    for srcloc in meta(m)
        contains(srcloc.name, name) || continue
        contains(srcloc.func, func) || continue
        contains(srcloc.file, file) || continue
        srcloc.enabled = enable
    end
    return nothing
end

"""
Register this module's `@tracepoint` callsites with Tracy.jl

This will allow tracepoints to appear in Tracy's Enable/Disable window, even if they
haven't been run yet. Using this macro is optional, but it's recommended to call it
from within your module's `__init__` method.
"""
macro register_tracepoints()
    srclocs = meta(__module__)
    return quote
        push!($modules, $__module__)
        foreach($Tracy.initialize!, $srclocs)
    end
end
