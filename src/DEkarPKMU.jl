module DEkarPKMU

export solve_model, solve_model_fast, solve_model_test
export Data, dataToJSON, JSONToData, initData, initDataXLSX, initSampleJSON
export generatePdfTest, generatePdf, testG

using JuMP, XLSX, JSON3, HiGHS, JSON, Pkg
Pkg.activate(".");

include(joinpath(@__DIR__, "input.jl"));
include(joinpath(@__DIR__, "model.jl"));
include(joinpath(@__DIR__, "pdfgen.jl"));

function modelTest()
    generatePdfTest();
end

end # module DEkarPKMU
