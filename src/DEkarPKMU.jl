module DEkarPKMU

export solve_model, solve_model_fast, Data, initDataXLSX, initData, dataToJSON

using JuMP, XLSX, JSON3

include(joinpath(@__DIR__, "input.jl"))
include(joinpath(@__DIR__, "model.jl"))
end # module DEkarPKMU
