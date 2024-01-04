using Formatting
using Plots

include("./pdfGen/varTemplate.jl");
function generatePdfTest()::String
    #data::Data = initDataXLSX("/Users/ole/Documents/Uni/WS2324/POM/master_thesis/230717_Energiesystemmodellierung_Input_Output.xlsx");
    data::Data = initData(initSampleJSON());
    model = solve_model_fast(HiGHS.Optimizer, data);
    pdfPath::String = generatePdf(model);
    pathArgument::Vector{String} = [pdfPath];
    #run(`open $pathArgument`);
end
function generatePdf(model::Model)::String
    dir::String = "./src/pdfGen";
    while isdir(dir)
        # create random id
        id::Int64 = rand(0:9223372036854775807);

        # create temp directory
        dir = string("./src/pdfGen/temp_", id);
    end
    mkdir(dir);
    graphNames::Vector{String} = ["simplePlot.png", "SOC.png"];
    generateGraphs(dir, graphNames, model);

    # create .typ file
    filePath::String = string(dir, "/report.typ");
    touch(filePath);

    # TODO: handle IO exceptions 
    # open report.typ tile
    file::IO = open(filePath, "w");

    # write to file
    # adjust paths to graphs to comply with typst requirements
    graphNames = map(path::String -> string("\"", ".", dir[13:end], "/", path, "\""), graphNames);
    arguments::Vector{String} = ["[hello]", "[Ole]", graphNames[1], graphNames[2]];
    argumentString::String = join(arguments, ", ");
    toWrite::String = format("#import \"../pageSettings.typ\":conf \n#show: doc => conf({:s}) \n", argumentString);
    write(file, toWrite);

    # close report.typ file
    close(file);

    # compile the report.typ file
    fileAsArgument::Vector{String} = [filePath];
    # TODO: make sure typst is installed!! (with the correct version)
    compileCommand::Cmd = `typst compile $fileAsArgument --root="/"`;
    run(compileCommand);

return string(filePath[1:end-3], "pdf");
end

function generateGraphs(dir::String, names::Vector{String}, model::Model)
    # sample plot
    samplePlot::Plots.Plot{Plots.GRBackend} = plot(rand(10), dpi=1000);
    samplePath::String = string(dir, "/", names[1]);
    savefig(samplePlot, samplePath);

    # plot SOC
    socPlot::Plots.Plot{Plots.GRBackend} = plot(value.(model[:SOC]), dpi=1000);
    socPath::String = string(dir, "/", names[2]);
    savefig(socPlot, socPath);
end

function testG()
    generateGraphs("/Users/ole/Documents/Uni/WS2324/POM/DEkarPKMU.jl/src/pdfGen", ["samplePlot.png"], Nothing);
end
