import gleam/http
import gleam/http/request as http_request
import gleam/httpc
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import openai/error
import openai/responses/decoders
import openai/responses/encoders
import openai/responses/types/request.{type Request, Request}
import openai/responses/types/response.{type Response}
import openai/types as shared

const responses_url = "https://api.openai.com/v1/responses"

pub fn default_request() -> Request {
  Request(
    model: shared.GPT41Mini,
    input: request.Text(""),
    temperature: None,
    stream: None,
    tool_choice: None,
    tools: None,
  )
}

pub fn model(config: Request, model: shared.Model) {
  Request(..config, model: model)
}

pub fn input(config: Request, input: String) -> Request {
  Request(..config, input: request.Text(input))
}

pub fn tool_choice(config: Request, tool_choice: request.ToolChoice) {
  Request(..config, tool_choice: Some(tool_choice))
}

pub fn tools(
  config: Request,
  tools: Option(List(request.Tools)),
  tool: request.Tools,
) {
  case tools {
    None -> Request(..config, tools: Some([tool]))
    Some(ts) -> Request(..config, tools: Some(list.prepend(ts, tool)))
  }
}

pub fn create(
  client client: String,
  request config: Request,
) -> Result(Response, error.OpenaiError) {
  // I think this assert is Ok
  let assert Ok(base_req) = http_request.to(responses_url)

  let body = json_body(config)

  let req =
    base_req
    |> http_request.prepend_header("Content-Type", "application/json")
    |> http_request.prepend_header("Authorization", "Bearer " <> client)
    |> http_request.set_body(body)
    |> http_request.set_method(http.Post)

  use resp <- result.try(httpc.send(req) |> error.replace_error())
  use result <- result.try(
    json.parse(resp.body, decoders.response_decoder())
    |> result.replace_error(error.BadResponse),
  )

  Ok(result)
}

// 
// region:    --- Json encoding
fn json_body(config: Request) -> String {
  json.object([
    #("model", shared.model_encoder(config.model)),
    case config.input {
      request.Text(input) -> #("input", json.string(input))
    },
    case config.temperature {
      Some(temperature) -> #("temperature", json.float(temperature))
      None -> #("temperature", json.null())
    },
    case config.stream {
      Some(stream) -> #("stream", json.bool(stream))
      None -> #("stream", json.null())
    },
    case config.tool_choice {
      Some(tool_choice) -> #(
        "tool_choice",
        encoders.tool_choice_encoder(tool_choice),
      )
      None -> #("tool_choice", json.null())
    },
    case config.tools {
      Some(tools) -> #(
        "tools",
        json.preprocessed_array(encoders.tools_encoder(tools)),
      )
      None -> #("tools", json.null())
    },
  ])
  |> json.to_string
}
