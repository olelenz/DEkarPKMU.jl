module DEkarPKMU

export solve_model, solve_model_fast, solve_model_var
export Data, dataToJSON, JSONToData, initData, initDataXLSX, initSampleJSON, validateUserData
export generatePdfTest, generatePdf, testG
export startBackend

using Pkg;
Pkg.activate("..");
#Pkg.instantiate();

using JuMP, XLSX, JSON3, HiGHS, JSON, Pkg, DataStructures
using Genie, Genie.Renderer.Json, Genie.Requests, HTTP, Formatting, Printf, Statistics
using MathOptInterface

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
