include("./pdfGen/varTemplate.jl");
function generatePdfTest()
    dir::String = "./pdfGen";
    while isdir(dir)
        # create random id
        id::Int64 = rand(0:9223372036854775807);

        # create temp directory
        dir= string("./pdfGen/temp_", id);
    end
    mkdir(dir);

    # create .typ file
    filePath::String = string(dir, "/report.typ");
    touch(filePath);

    # TODO: handle IO exceptions 
    # open report.typ tile
    file::IO = open(filePath, "w");

    # write to file
    toWrite::String = string(HEADING, "\n\n This is going to be the report!")
    write(file, toWrite);

    # close report.typ file
    close(file);

    # compile the report.typ file
    fileAsArgument::Vector{String} = [filePath];
    # TODO: make sure typst is installed!! (with the correct version)
    compileCommand::Cmd = `typst compile $fileAsArgument`;
    run(compileCommand);
end
