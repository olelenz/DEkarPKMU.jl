using Genie, Genie.Renderer.Json, Genie.Requests

function startBackend()
    println("hello backend");
    route("/hello.json") do
        json("Hello World");
    end

    route("/processModelInput", method = POST) do
        @show jsonpayload()
        @show rawpayload()
        if(jsonpayload === nothing)
            println("TODO: throw error here");
        end
        data::Data = initData(jsonpayload());
        model = solve_model_fast(HiGHS.Optimizer, data);
        generatePdf(model);
        println(data.WACC);
    end

    up(8001, async = false);
end
