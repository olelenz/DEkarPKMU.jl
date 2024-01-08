module DEkarPKMU

export solve_model, solve_model_fast, solve_model_test
export Data, dataToJSON, JSONToData, initData, initDataXLSX, initSampleJSON
export generatePdfTest, generatePdf, testG
export startBackend

using JuMP, XLSX, JSON3, HiGHS, JSON, Pkg, Genie
#Pkg.activate(".");

include(joinpath(@__DIR__, "input.jl"));
include(joinpath(@__DIR__, "model.jl"));
include(joinpath(@__DIR__, "pdfgen.jl"));
include(joinpath(@__DIR__, "backend.jl"));

function modelTest()
    generatePdfTest();
end

function __init__()
    startBackend()
end

end # module DEkarPKMU
