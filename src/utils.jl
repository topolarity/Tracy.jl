function extract_keywords(ex0)
    kws = Dict{Symbol, Any}()
    arg = ex0[end]
    for i in 1:length(ex0)-1
        x = ex0[i]
        if x isa Expr && x.head === :(=) # Keyword given of the form "foo=bar"
            if length(x.args) != 2
               error("Invalid keyword argument: $x")
            end
            kws[x.args[1]] = esc(x.args[2])
        else
            return error("@tracepoint expects only one non-keyword argument")
        end
    end
    return kws, arg
end
