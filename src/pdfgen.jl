function generatePdfTest()
    # create random id
    id::Int64 = rand(Int64);

    # create temp directory
    dirName::String = string("./pdfGen/temp_", id);
    println(dirName);
    mkdir(dirName);

end
