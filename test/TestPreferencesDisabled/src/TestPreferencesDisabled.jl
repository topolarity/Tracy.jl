module TestPreferencesDisabled

using Tracy

function time_something()
    for _ in 1:100
        @tracepoint "timing_prefs_disabled" rand(100)
    end
end

using Preferences
const foo = @load_preference("testing_inside", true)

end # module TestPreferencesDisabled
