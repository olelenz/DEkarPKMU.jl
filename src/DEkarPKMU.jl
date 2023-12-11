module DEkarPKMU

export solve_model, solve_model_fast, solve_model_test
export Data, dataToJSON, JSONToData, initData, initDataXLSX, initSampleJSON

using JuMP, XLSX, JSON3, HiGHS, JSON

include(joinpath(@__DIR__, "input.jl"))
include(joinpath(@__DIR__, "model.jl"))

data::Data = initData(initSampleJSON());

#model = solve_model_test(HiGHS.Optimizer, data);

#print(model);  # overview of the solved model

# TODO: create output visualisations
# TODO: return structured result

end # module DEkarPKMU
