using Genie, Genie.Renderer, Genie.Renderer.Html, Genie.Renderer.Json, Genie.Requests

route("/hello.json") do
  json("Hello World")
end

route("/processModelInput", method = POST) do
  @show jsonpayload()
  @show rawpayload()

  json("Hello $(jsonpayload()["usage_WT"])")
end

up(8001, async = false)
