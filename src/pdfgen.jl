using Formatting
using Plots

include("./pdfGen/varTemplate.jl");
function generatePdfTest()
    #data::Data = initDataXLSX("/Users/ole/Documents/Uni/WS2324/POM/master_thesis/230717_Energiesystemmodellierung_Input_Output.xlsx");
    data::Data = initDataFromString(initSampleJSON());
    id::Int64 = rand(0:9223372036854775807);
    model = solve_model_fast(HiGHS.Optimizer, data);
    pdfPath::String = generatePdf(model, id);
    run(`open $pdfPath`);
end


function generatePdf(model::Model, id::Int64)
    dir::String = string(joinpath(@__DIR__, joinpath("pdfGen","temp_")), id);
    if(isdir(dir))
        rm(dir, recursive=true);
    end
    mkdir(dir)
    graphNames::Vector{String} = ["Eigenvebrauch.png", "Autarkiegrad.png", "SOC.png"];
    generateGraphs(dir, graphNames, model);

    # create .typ file
    filePath::String = joinpath(dir, "report.typ");
    touch(filePath);

    # TODO: handle IO exceptions 
    # open report.typ tile
    file::IO = open(filePath, "w");

    # write to file
    # adjust paths to graphs to comply with typst requirements
    graphNames = map(path::String -> string("\"", replace(joinpath(dir, path), "\\"=>"\\\\"), "\""), graphNames);
    outputData::String = buildTypstOutputDataDictionary(model, dir);
    arguments::Vector{String} = [string("", id), "[Ole]", graphNames[1], graphNames[2], graphNames[3], outputData];
    argumentString::String = join(arguments, ", ");
    toWrite::String = format("#import \"..\\pageSettings.typ\":conf \n#show: doc => conf({:s}) \n", argumentString);
    write(file, toWrite);

    # close report.typ file
    close(file);

    # compile the report.typ file
    filePath = replace(filePath, "\\" => "\\\\");
    fileAsArgument::Vector{String} = [filePath];
    # TODO: make sure typst is installed!! (with the correct version)
    command0 = "compile";
    # On Windows:
    command1 = raw"C:\Users\simulating\AppData\Local\Microsoft\WinGet\Packages\Typst.Typst_Microsoft.Winget.Source_8wekyb3d8bbwe\typst-x86_64-pc-windows-msvc\typst.exe";
    command2 = "--root=\\";
    compileCommand::Cmd = `cmd /c $command1 $command0 $fileAsArgument $command2`;

    # On Mac:
    command3 = "typst";
    command4 = "--root=\\";
    compileCommandMac::Cmd = `$command3 $command0 $fileAsArgument $command4`;
    
    run(compileCommand);
end

function generateKennzahlen(model::Model)::Dict{String, Number}
    out::Dict{String, Number} = Dict{String, Number}();
    out["LeistungElektrolyse"] = sum(value.(model[:EL_output]));
    out["LeistungBrennstoffzelle"] = sum(value.(model[:FC_output]));
    out["Wasserstofftankfuellstand"] = mean(value.(model[:H]));
    out["VerkaufterStrom"] = value.(model[:Total_sell]);
    out["EingekaufterStrom"] = value.(model[:Total_buy]);
    out["BatterieInput"] = mean(value.(model[:R_Bat_in]));
    out["VerwendeteEnergie"] = value.(model[:Total_demand]);
    out["NPV"] = value.(model[:NPV_annual_costs]) * -1;
    return out;
end

function buildTypstOutputDataDictionary(model::Model, dir::String)::String
    data::Dict{String, Number} = generateKennzahlen(model);
    write(joinpath(dir, "Kennzahlen.txt"), JSON3.write(data))
    out::String = "(";
    out = string(out, "LeistungElektrolyse: ", formatNum(data["LeistungElektrolyse"]));
    out = string(out, ",LeistungBrennstoffzelle: ", formatNum(data["LeistungBrennstoffzelle"]));
    out = string(out, ",Wasserstofftankfuellstand: ", formatNum(data["Wasserstofftankfuellstand"]));
    out = string(out, ",VerkaufterStrom: ", formatNum(data["VerkaufterStrom"]));
    out = string(out, ",EingekaufterStrom: ", formatNum(data["EingekaufterStrom"]));
    out = string(out, ",BatterieInput: ", formatNum(data["BatterieInput"]));
    out = string(out, ",VerwendeteEnergie: ", formatNum(data["VerwendeteEnergie"]));
    out = string(out, ",NPV: ", formatNum(data["NPV"]));

    return string(out, ")");
end
function formatNum(x,fmt="%15.2f")::String
    return string("\"", Printf.format(Printf.Format(fmt), x), "\"")
end

function generateGraphs(dir::String, names::Vector{String}, model::Model)
    # Eigenverbrauch pie chart
    labelsEigenverbrauch::Vector{String} = ["verkaufter Strom", "eigens genutzter Strom"];

    total_demand::Float64 = value.(model[:Total_demand]);
    total_sell::Float64 = value.(model[:Total_sell]);
    sum_energy_consumption::Float64 = total_demand + total_sell;
    valuesEigenverbrauch::Vector{Float64} = [total_sell/sum_energy_consumption, total_demand/sum_energy_consumption];

    eigenverbrauchPlot::Plots.Plot{Plots.GRBackend} = pie(labelsEigenverbrauch, valuesEigenverbrauch, dpi = 1000, title = "Eigenverbrauch");
    eigenverbrauchPath::String = joinpath(dir, names[1]);
    savefig(eigenverbrauchPlot, eigenverbrauchPath);

    # Autarkiegrad
    labelsAutarkiegrad::Vector{String} = ["eingekaufter Strom", "generierter Strom"];

    total_buy::Float64 = value.(model[:Total_buy]);
    total_gen::Float64 = value.(model[:Total_PV_GEN]) + value.(model[:Total_WT_GEN]);
    sum_energy_input::Float64 = total_buy + total_gen;
    valuesAutarkiegrad::Vector{Float64} = [total_buy/sum_energy_input, total_gen/sum_energy_input];

    autarkiegradPlot::Plots.Plot{Plots.GRBackend} = pie(labelsAutarkiegrad, valuesAutarkiegrad, dpi = 1000, title = "Autarkiegrad");
    autarkiegradPath::String = joinpath(dir, names[2]);
    savefig(autarkiegradPlot, autarkiegradPath);

    # plot SOC
    socPlot::Plots.Plot{Plots.GRBackend} = plot(value.(model[:SOC]), dpi=1000);
    socPath::String = joinpath(dir, names[3]);
    savefig(socPlot, socPath);
end

function testG()
    generateGraphs("/Users/ole/Documents/Uni/WS2324/POM/DEkarPKMU.jl/src/pdfGen", ["samplePlot.png"], Nothing);
end
