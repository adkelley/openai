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
import openai/types/shared

const responses_url = "https://api.openai.com/v1/responses"

pub fn default_request() -> Request {
  Request(
    model: shared.GPT41Mini,
    input: request.InputText(""),
    instructions: None,
    temperature: None,
    stream: None,
    tool_choice: None,
    tools: None,
  )
}

pub fn model(config: Request, model: shared.Model) {
  Request(..config, model:)
}

pub fn input(config: Request, input: request.Input) -> Request {
  Request(..config, input:)
}

pub fn instructions(config: Request, instructions: Option(String)) -> Request {
  Request(..config, instructions:)
}

pub fn function_tool_choice(
  config: Request,
  tool_choice: request.FunctionToolChoice,
) {
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

  let body =
    encoders.config_encoder(config)
    |> json.to_string
  // |> echo

  let req =
    base_req
    |> http_request.prepend_header("Content-Type", "application/json")
    |> http_request.prepend_header("Authorization", "Bearer " <> client)
    |> http_request.set_body(body)
    |> http_request.set_method(http.Post)

  use resp <- result.try(
    httpc.configure()
    |> httpc.timeout(90_000)
    |> httpc.dispatch(req)
    |> error.replace_error(),
  )
  // echo resp.body
  use result <- result.try(
    json.parse(resp.body, decoders.response_decoder())
    // |> echo
    |> result.replace_error(error.BadResponse),
  )

  Ok(result)
}
