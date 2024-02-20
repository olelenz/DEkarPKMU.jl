using Formatting
using Plots
using Plots.PlotMeasures

include("./pdfGen/varTemplate.jl");
function generatePdfTest()
    #data::Data = initDataXLSX("/Users/ole/Documents/Uni/WS2324/POM/master_thesis/230717_Energiesystemmodellierung_Input_Output.xlsx");
    data::Data = initDataFromString(initSampleJSON());
    id::Int64 = rand(0:9223372036854775807);
    model = solve_model_fast(HiGHS.Optimizer, data);
    generatePdf(model, id, data);
end


function generatePdf(model::Model, id::Int64, data::Data)
    dir::String = string(joinpath(@__DIR__, joinpath("pdfGen","temp_")), id);
    if(isdir(dir))
        rm(dir, recursive=true);
    end
    mkdir(dir)
    graphNames::Vector{String} = ["Eigenvebrauch.png", "Autarkiegrad.png", "Lastverlauf.png"];
    generateGraphs(dir, graphNames, model, data);

    # create .typ file
    filePath::String = joinpath(dir, "report.typ");
    touch(filePath);

    # open report.typ tile
    file::IO = open(filePath, "w");

    # write to file
    # adjust paths to graphs to comply with typst requirements
    graphNames = map(path::String -> string("\"", replace(joinpath(dir, path), "\\"=>"\\\\"), "\""), graphNames);
    inputData::String = buildTypstInputDataDictionary(data);
    outputData::String = buildTypstOutputDataDictionary(model, dir);
    arguments::Vector{String} = [string("", id),  graphNames[1], graphNames[2], graphNames[3], inputData, outputData];
    argumentString::String = join(arguments, ", ");
    settingsToInclude::String = joinpath("..", "pageSettings.typ");
    toWrite::String = format("#import \"{:s}\":conf \n#show: doc => conf({:s}) \n", settingsToInclude, argumentString);
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
    compileCommandMac::Cmd = `$command3 $command0 $fileAsArgument --root="/"`;
    
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
    out["NPV"] = value.(model[:NPV_annual_costs]);
    out["KapazitaetWasserstofftank"] = value.(model[:c_H]);
    out["KapazitaetBatterie"] = value.(model[:c_bat]);
    out["GesamteEnergiekosten"] = value.(model[:EC]);
    out["Investitionen"] = value.(model[:Invest_tot]);
    out["Restwerte"] = value.(model[:Residual]);
    return out;
end

function buildTypstInputDataDictionary(data::Data)::String
    out::String = "(";
    out = string(out, "WACC: ", formatNum(data.WACC));
    out = string(out, ",inflation: ", formatNum(data.inflation*100));
    out = string(out, ",Projektlaufzeit: ", formatNum(data.years, "%12.0f"));
    out = string(out, ",Wind: ", data.usage_WT);
    out = string(out, ",PV: ", data.usage_PV);
    out = string(out, ",Batterie: ", data.usage_bat);
    out = string(out, ",H2: ", data.usage_H);
    out = string(out, ",PVFlaeche: ", formatNum(data.max_capa_PV));
    out = string(out, ",WTFlaeche: ", formatNum(data.max_capa_WT));
    out = string(out, ",GesStromverbrauch: ", formatNum(sum(data.edem)));
    out = string(out, ",Schichten: ", data.shifts);
    out = string(out, ",StrompreisEinkauf: ", formatNum(data.beta_buy[1]));
    out = string(out, ",StrompreisVerkauf: ", formatNum(data.beta_sell[1]));
    out = string(out, ",Netzentgelt: ", formatNum(data.beta_buy_LP));  # TODO: validate
    out = string(out, ",Fernwaermepreis: ", formatNum(data.heat_price));
    out = string(out, ",Annuitaetenfaktor: ", formatNum(data.CRF_project));
    return string(out, ")");
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

    out = string(out, ",KapazitaetWasserstofftank: ", formatNum(data["KapazitaetWasserstofftank"]));
    out = string(out, ",KapazitaetBatterie: ", formatNum(data["KapazitaetBatterie"]));
    out = string(out, ",GesamteEnergiekosten: ", formatNum(data["GesamteEnergiekosten"]));
    out = string(out, ",Investitionen: ", formatNum(data["Investitionen"]));
    out = string(out, ",Restwerte: ", formatNum(data["Restwerte"]));

    return string(out, ")");
end

function formatNum(x,fmt="%12.2f")::String
    return string("\"", Printf.format(Printf.Format(fmt), x), "\"")
end

function generateGraphs(dir::String, names::Vector{String}, model::Model, data::Data)
    # Eigenverbrauch pie chart
    labelsEigenverbrauch::Vector{String} = ["verkaufter Strom", "eigens genutzter Strom"];

    total_demand::Float64 = value.(model[:Total_demand]);
    total_sell::Float64 = value.(model[:Total_sell]);
    sum_energy_consumption::Float64 = total_demand + total_sell;
    valuesEigenverbrauch::Vector{Float64} = [total_sell/sum_energy_consumption, total_demand/sum_energy_consumption];

    eigenverbrauchPlot::Plots.Plot{Plots.GRBackend} = pie(labelsEigenverbrauch, valuesEigenverbrauch, dpi = 1000, title = "Eigenverbrauch");
    eigenverbrauchPath::String = joinpath(dir, names[1]);
    savefig(eigenverbrauchPlot, eigenverbrauchPath);

    # Autarkiegrad pie charts
    labelsAutarkiegrad::Vector{String} = ["eingekaufter Strom", "generierter Strom"];

    total_buy::Float64 = value.(model[:Total_buy]);
    total_gen::Float64 = value.(model[:Total_PV_GEN]) + value.(model[:Total_WT_GEN]);
    sum_energy_input::Float64 = total_buy + total_gen;
    println(total_buy)
    println(sum_energy_input)
    println(total_gen)
    println(sum_energy_input)
    valuesAutarkiegrad::Vector{Float64} = [total_buy/sum_energy_input, total_gen/sum_energy_input];

    autarkiegradPlot::Plots.Plot{Plots.GRBackend} = pie(labelsAutarkiegrad, valuesAutarkiegrad, dpi = 1000, title = "Autarkiegrad");
    autarkiegradPath::String = joinpath(dir, names[2]);
    savefig(autarkiegradPlot, autarkiegradPath);

    # plot avg Lastverlauf
    sizeWeek::Int64 = 168;
    lastverlauf::Vector{Float64} = data.edem;
    avgLastverlauf::Vector{Float64} = lastverlauf[25:sizeWeek+24];
    for i = 2:51
        avgLastverlauf = avgLastverlauf + lastverlauf[(i-1)*sizeWeek + 25 : i*sizeWeek + 24];
    end
    avgLastverlauf = avgLastverlauf / 51;
    daysSeperator::Vector{Int64} = [1, 24, 48, 72, 96, 120, 144, 168];
    days::Vector{Int64} = [12, 36, 60, 84, 108, 132, 156];
    labels::Vector{String} = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Freitag", "Samstag", "Sonntag"];
    axis::Tuple{Vector{Int64}, Vector{String}} = (days, labels);
    outputPlot::Plots.Plot{Plots.GRBackend} = plot(avgLastverlauf, xticks = axis, dpi=1000, xlabel = "Wochentage", ylabel = "kW", size = (1700, 500), label = "durchschnittlicher Lastverlauf", title = "durchschnittlicher Lastverlauf", legend = false, bottom_margin=40px, left_margin=40px);
    outputPlot = vline!(daysSeperator, linestyle=:dot, label = "");
    lastverlaufPath::String = joinpath(dir, names[3]);
    savefig(outputPlot, lastverlaufPath);
end

function testG()
    generateGraphs("/Users/ole/Documents/Uni/WS2324/POM/DEkarPKMU.jl/src/pdfGen", ["samplePlot.png"], Nothing);
end
