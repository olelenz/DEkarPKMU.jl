
function startBackend()
    currentJobsSet::Set{Int64} = Set{Int64}();
    processingQueue::Queue{Int64} = Queue{Int64}();
    taskList::Dict{Int64, Task} = Dict();
    taskData::Dict{Int64, Dict{String, Any}} = Dict();

    function startJob()
        currentId::Int64 = dequeue!(processingQueue);
        jsonData::Dict{String, Any} = taskData[currentId];
        data::Data = initData(jsonData);
        model = solve_model_fast(HiGHS.Optimizer, data);
        status::MathOptInterface.TerminationStatusCode = termination_status(model);
        if(string(status) != "OPTIMAL" && string(status) != "LOCALLY_SOLVED")
            error("Model not solveable!");
        else
            generatePdf(model, data.id, data);
        end
    end

    route("/getStatus/:id", method = GET) do 
        response::HTTP.Messages.Response = HTTP.Messages.Response();
        response.headers = (["Content-Type" => "text/plain", "charset" => "utf-8"]);
        
        local id::Int64;
        try
            id = parse(Int64, payload(:id));
        catch _
            response.status = 400;
            response.body = format("Id: {:s} not of type Int64.", payload(:id));
            return response;
        end

        message::String = format("Task for job {:s} ", id);
        local currentTask::Task;
        try
            currentTask = taskList[id];
        catch _
            response.status = 400;
            response.body = format("No task for job {:s}.", id);
            return response;
        end

        response.status = 200;
        if (istaskfailed(currentTask))
            msg::String = "";
            try
                fetch(currentTask);
            catch ex
                try
                    msg = string(ex.task.exception.msg)
                catch
                    msg = string(ex.task.exception)
                end
            end
            response.body = string(message, "failed: ", msg);
        elseif (!istaskstarted(currentTask))
            response.body = string(message, "not started.");
        elseif (istaskstarted(currentTask) && !istaskdone(currentTask))
            response.body = string(message, "is running.");
        elseif (istaskdone(currentTask))
            response.body = string(message, "is done.");
        end
        return response;
    end

    route("/cleanJob/", method = POST) do 
        response::HTTP.Messages.Response = HTTP.Messages.Response();
        response.headers = (["Content-Type" => "text/plain", "charset" => "utf-8"]);

        local idJson::Any;
        local id::Int64;
        try
            idJson = JSON.parse(rawpayload())["id"];
        catch _
            response.status = 400;
            response.body = "JSON key id in body missing.";
            return response;
        end
        try
            id = idJson;
        catch _
            response.status = 400;
            response.body = format("Id: {:s} not of type Int64.", idJson);
            return response;
        end

        try
            if(!istaskdone(taskList[id]))
                response.status = 400;
                response.body = format("Task with id {:s} not done.", id);
                return response;
            end
        catch _
            response.status = 400;
            response.body = format("Task with id {:s} not found.", id);
            return response;
        end
        
        delete!(currentJobsSet, id);
        delete!(taskList, id);
        delete!(taskData, id)
        pathToRemove::String = joinpath(@__DIR__, string("pdfgen/temp_", id));
        rm(pathToRemove, recursive = true);

        response.status = 200;
        response.body = format("Cleaned job {:s}.", id);
        return response;
    end
    
    route("/getResults/:id", method = GET) do 
        response::HTTP.Messages.Response = HTTP.Messages.Response();
        response.headers = (["Content-Type" => "text/plain", "charset" => "utf-8"]);
        local id::Int64;
        try
            id = parse(Int64, payload(:id));
        catch _
            response.status = 400;
            response.body = format("Id: {:s} not of type Int64.", payload(:id));
            return response;
        end

        try
            if(!istaskdone(taskList[id]))
                response.status = 400;
                response.body = format("Task with id {:s} not done.", id);
                return response;
            end
            if(istaskfailed(taskList[id]))
                response.status = 400;
                response.body = format("Task with id {:s} failed.", id);
                return response;
            end
        catch _
            response.status = 400;
            response.body = format("Task with id {:s} not found.", id);
            return response;
        end
        
        basePath::String = joinpath(@__DIR__, string("pdfGen/temp_", id));
        pathToPdf::String = joinpath(basePath, "report.pdf");
        pathToImg1::String = joinpath(basePath, "Eigenverbrauch.png");
        pathToImg2::String = joinpath(basePath, "Autarkiegrad.png");
        pathToImg3::String = joinpath(basePath, "SOC.png");
        # TODO: add text output data
        returnDictionary= Dict(
            "pathToPdf" => pathToPdf, 
            "pathToImg1" => pathToImg1, 
            "pathToImg2" => pathToImg2, 
            "pathToImg3" => pathToImg3);

        kennzahlenDictionary::Dict{String, Number} = JSON3.read(read(joinpath(basePath, "Kennzahlen.txt"), String), Dict{String, Number});
        kennzahlenDictionaryString::Dict{String, String} = Dict{String, String}();
        for (key, value) in kennzahlenDictionary
            kennzahlenDictionaryString[key] = string(Printf.format(Printf.Format("%.2f"), value));
        end
        returnDictionary = merge(returnDictionary, kennzahlenDictionaryString);
        
        return JSON.json(returnDictionary);
    end

    route("/processModelInput", method = POST) do
        response::HTTP.Messages.Response = HTTP.Messages.Response();
        response.headers = (["Content-Type" => "text/plain", "charset" => "utf-8","Access-Control-Allow-Origin" => "*"]);

        local idJson::Any;
        local id::Int64;
        try
            idJson = JSON.parse(rawpayload())["id"];
        catch _
            response.status = 400;
            response.body = "JSON key id in body missing.";
            return response;
        end
        try
            id = idJson;
        catch _
            response.status = 400;
            response.body = format("Id: {:s} not of type Int64.", idJson);
            return response;
        end

        try
            validateUserData(JSON.parse(rawpayload()));
        catch e
            response.status = 400;
            response.body = format("Input data not correct: {:s}", e.msg);
            return response;
        end

        task::Task = Task(startJob);
        push!(currentJobsSet, id);
        enqueue!(processingQueue, id);
        taskList[id] = task;

        taskData[id] = JSON.parse(rawpayload());

        @async begin
            sleep(1);
            schedule(task);
            yield();
        end
        #startJob()
    
        response.status = 202;
        response.body = format("Started job {:s}.", id);
        return response;
    end

    Genie.config.run_as_server = true
    Genie.config.cors_headers["Access-Control-Allow-Origin"] = "http://localhost:8001"
    Genie.config.cors_headers["Access-Control-Allow-Headers"] = "Content-Type"
    Genie.config.cors_headers["Access-Control-Allow-Methods"] ="GET,POST" 
    Genie.config.cors_allowed_origins = ["*"]
    up(8001, async = false);
end
