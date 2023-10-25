module DEkarPKMU

export solve_model

using JuMP

include(joinpath(@__DIR__, "model.jl"))
include(joinpath(@__DIR__, "input.jl"))
end # module DEkarPKMU
