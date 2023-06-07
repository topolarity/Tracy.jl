module TestPreferencesFiltered

using Tracy

function time_something()
    for _ in 1:100
        @tracepoint "testprefs_zone1" rand(100)
        @tracepoint "testprefs_zone2" rand(100)
        @tracepoint "testprefs_zone21" rand(100)
        @tracepoint "testprefs_zone22" rand(100)
        @tracepoint "testprefs_zone23" rand(100)
        @tracepoint "testprefs_zone24" rand(100)
        @tracepoint "testprefs_zone3" rand(100)
        @tracepoint "testprefs_foo" rand(100)
    end
end

end # module TestPreferencesFiltered
