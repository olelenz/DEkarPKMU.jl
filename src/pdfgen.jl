using Formatting

include("./pdfGen/varTemplate.jl");
function generatePdfTest()
    dir::String = "./pdfGen";
    while isdir(dir)
        # create random id
        id::Int64 = rand(0:9223372036854775807);

        # create temp directory
        dir = string("./pdfGen/temp_", id);
    end
    mkdir(dir);
    graphNames::Vector{String} = ["simplePlot.png"];
    generateGraphs(dir, graphNames);

    # create .typ file
    filePath::String = string(dir, "/report.typ");
    touch(filePath);

    # TODO: handle IO exceptions 
    # open report.typ tile
    file::IO = open(filePath, "w");

    # write to file
    # adjust paths to graphs to comply with typst requirements
graphNames = map(path::String -> string("\"", ".", dir[9:end], "/", path, "\""), graphNames);
    arguments::Vector{String} = ["[hello]", "[Ole]", graphNames[1]];
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
end

function generateGraphs(dir::String, names::Vector{String})
    samplePlot::Plots.Plot{Plots.GRBackend} = plot(rand(10), dpi=1000);
    samplePath::String = string(dir, "/", names[1]);
    savefig(samplePlot, samplePath);
end

function testG()
    generateGraphs("/Users/ole/Documents/Uni/WS2324/POM/DEkarPKMU.jl/src/pdfGen", ["samplePlot.png"]);
end
