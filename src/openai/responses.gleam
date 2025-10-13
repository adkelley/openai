import gleam/http
import gleam/http/request as http_request
import gleam/httpc
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import openai/error
import openai/responses/decoder
import openai/responses/types/request.{type Request, Request}
import openai/responses/types/response.{type Response}
import openai/shared/types as shared

const responses_url = "https://api.openai.com/v1/responses"

pub fn default_request() -> Request {
  Request(
    model: shared.GPT41Mini,
    input: request.Text(""),
    temperature: None,
    stream: None,
  )
}

pub fn add_input(config: Request, input: String) -> Request {
  Request(..config, input: request.Text(input))
}

pub fn create(
  client client: String,
  request config: Request,
) -> Result(Response, error.OpenaiError) {
  // I think this assert is Ok
  let assert Ok(base_req) = http_request.to(responses_url)

  // let body = ""
  let body = json_body(config)

  let req =
    base_req
    |> http_request.prepend_header("Content-Type", "application/json")
    |> http_request.prepend_header("Authorization", "Bearer " <> client)
    |> http_request.set_body(body)
    |> http_request.set_method(http.Post)

  use resp <- result.try(httpc.send(req) |> error.replace_error())
  use result <- result.try(
    json.parse(resp.body, decoder.response_decoder())
    |> result.replace_error(error.BadResponse),
  )

  Ok(result)
}

// 
// region:    --- Json encoding
fn json_body(config: Request) -> String {
  json.object([
    #("model", json.string(shared.describe_model(config.model))),
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
  ])
  |> json.to_string
}
