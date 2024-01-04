module DEkarPKMU

export solve_model, solve_model_fast, solve_model_test
export Data, dataToJSON, JSONToData, initData, initDataXLSX, initSampleJSON
export generatePdfTest, generatePdf, testG

using JuMP, XLSX, JSON3, HiGHS, JSON, Pkg
Pkg.activate(".");

include(joinpath(@__DIR__, "input.jl"));
include(joinpath(@__DIR__, "model.jl"));
include(joinpath(@__DIR__, "pdfgen.jl"));


function test()
    #data::Data = initData(initSampleJSON());
    data::Data = initDataXLSX("/Users/ole/Documents/Uni/WS2324/POM/master_thesis/230717_Energiesystemmodellierung_Input_Output.xlsx");
    model = solve_model_fast(HiGHS.Optimizer, data);
    #print(model);  # overview of the solved model
    
    # TODO: create output visualisations
    # TODO: return structured result
    return model;
end 


end # module DEkarPKMU
