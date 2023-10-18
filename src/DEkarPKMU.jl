module DEkarPKMU

export solve_model

using JuMP

include(joinpath(@__DIR__, "model.jl"))
end # module DEkarPKMU
