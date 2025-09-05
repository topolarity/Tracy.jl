# This file is a part of Tracy.jl. License is MIT: See LICENSE.md

_is_func_def(ex) = Meta.isexpr(ex, :function) || Base.is_short_function_def(ex) || Meta.isexpr(ex, :->)
const TRACY_CONTEXT_TLS_KEY = :current_tracy_ctx

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
    @tracepoint "name" color=<color> enabled=<expr> <expression>

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
be changed at runtime. The tracepoint can be dynamically disabled or enabled
by using the `enabled` keyword argument which should be a boolean expression.

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

julia> @tracepoint "pow2" color=:green x^2; # green

julia> @tracepoint "pow3" color=:0xFF0000 x^3; # red

julia> @tracepoint "pow4" color=(255, 165, 0) x^4; # orange

julia> timings_enabled() = rand() < 0.5;

julia> @tracepoint "pow5" enabled=timings_enabled() x^5; # enabled only if timings_enabled() is true
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
    if haskey(def, :args)
        def[:args] = map(esc, def[:args])
    end
    if haskey(def, :kwargs)
        def[:kwargs] = map(esc, def[:kwargs])
    end
    if haskey(def, :whereparams)
        def[:whereparams] = map(esc, def[:whereparams])
    end
    if haskey(def, :rtype)
        def[:rtype] = esc(def[:rtype])
    end
    def[:body] = _tracepoint(name, string(function_name), def[:body], mod, source; kws...)
    cdef = combinedef(def)
    # Replace function definition line number node with that from source
    @assert def[:body].args[1] isa LineNumberNode
    def[:body].args[1] = source
    return cdef
end

function _tracepoint(name::Union{String, Nothing}, func::Union{String, Nothing}, ex::Expr, mod::Module, source::LineNumberNode; color::Union{Integer,Symbol,NTuple{3,Integer}}=0, enabled=true)
    filepath = string(source.file)
    line = source.line

    srcloc = TracySrcLoc(name, func, filepath, line, color, mod, true)
    push!(tracymeta(mod), srcloc)

    N = length(tracymeta(mod))
    m_id = invokelatest(getfield, mod, ID)

    return quote
        if tracepoint_enabled(Val($m_id), Val($N))
            if $srcloc.file == C_NULL
                initialize!($srcloc)
            end
            enabled = $(esc(enabled))::Bool
            local ctx = @ccall libtracy.___tracy_emit_zone_begin(pointer_from_objref($srcloc)::Ptr{Cvoid},
                                                                 ($srcloc.enabled != 0 && enabled)::Cint)::TracyZoneContext
            tls = task_local_storage()
            stack = get!(Vector{TracyZoneContext}, tls, TRACY_CONTEXT_TLS_KEY)::Vector{TracyZoneContext}
            push!(stack, ctx)
        end
        $(Expr(:tryfinally,
            :($(esc(ex))),
            quote
                if tracepoint_enabled(Val($m_id), Val($N))
                    @ccall libtracy.___tracy_emit_zone_end(ctx::TracyZoneContext)::Cvoid
                end
                pop!(stack)
            end
        ))
    end
end

function _get_current_tracy_ctx()
    ctx_v = get(task_local_storage(), TRACY_CONTEXT_TLS_KEY, nothing)
    if ctx_v === nothing
        error("must be called from within a @tracepoint")
    end
    return ctx_v[end]
end

"""
    set_zone_name!(name)

Set the name of the current zone. This must be called from within a `@tracepoint`.
"""
function set_zone_name!(name)
    ctx = _get_current_tracy_ctx()
    str = string(name)
    @ccall libtracy.___tracy_emit_zone_name(ctx::TracyZoneContext, str::Ptr{UInt8}, length(str)::Csize_t)::Cvoid
    return nothing
end

"""
    set_zone_color!(color::Union{Integer,Symbol,NTuple{3,Integer}})

Set the color of the current zone. This must be called from within a `@tracepoint`.
"""
function set_zone_color!(color::Union{Integer,Symbol,NTuple{3,Integer}})
    ctx = _get_current_tracy_ctx()
    @ccall libtracy.___tracy_emit_zone_color(ctx::TracyZoneContext, _tracycolor(color)::UInt32)::Cvoid
    return nothing
end

"""
    configure_tracepoint

Enable/disable a set of tracepoint(s) in the provided modules by invalidating any
existing code containing the tracepoint(s).

!!! warning
    This invalidates the code generated for all functions containing the selected zones.

    This will trigger re-compilation for these functions and may cause undesirable latency.
    It is strongly recommended to use `enable_tracepoint` instead.
"""
function configure_tracepoint(m::Module, enable::Bool; name="", func="", file="")
    m_id = invokelatest(getfield, m, ID)
    for (i, srcloc) in enumerate(tracymeta(m))
        contains(srcloc.name, name) || continue
        contains(srcloc.func, func) || continue
        contains(srcloc.file, file) || continue
        Core.eval(m, :($Tracy.tracepoint_enabled(::Val{$m_id}, ::Val{$i}) = $enable))
    end
    return nothing
end

"""
    enable_tracepoint

Enable/disable a set of tracepoint(s) in the provided modules, based on whether they
match the filters provided for `name`/`func`/`file`.
"""
function enable_tracepoint(m::Module, enable::Bool; name="", func="", file="")
    for srcloc in tracymeta(m)
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
    srclocs = tracymeta(__module__)
    return quote
        push!($modules, $__module__)
        foreach($Tracy.initialize!, $srclocs)
    end
end
