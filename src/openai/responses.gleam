import gleam/http
import gleam/http/request as http_request
import gleam/httpc
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import openai/error
import openai/types/responses/create_response.{
  type CreateResponse, CreateResponse,
} as cr

// import openai/types/responses/decoders
import openai/types/responses/response.{type Response}
import openai/types/shared

const responses_url = "https://api.openai.com/v1/responses"

pub fn default_request() -> CreateResponse {
  CreateResponse(
    model: shared.GPT41Mini,
    input: cr.Input(""),
    instructions: None,
    temperature: None,
    stream: None,
    tool_choice: None,
    tools: None,
  )
}

pub fn model(config: CreateResponse, model: shared.Model) {
  CreateResponse(..config, model:)
}

pub fn input(config: CreateResponse, input: cr.Input) -> CreateResponse {
  CreateResponse(..config, input:)
}

pub fn instructions(
  config: CreateResponse,
  instructions: Option(String),
) -> CreateResponse {
  CreateResponse(..config, instructions:)
}

pub fn function_tool_choice(
  config: CreateResponse,
  tool_choice: cr.FunctionToolChoice,
) {
  CreateResponse(..config, tool_choice: Some(tool_choice))
}

pub fn tools(
  config: CreateResponse,
  tools: Option(List(cr.Tools)),
  tool: cr.Tools,
) {
  case tools {
    None -> CreateResponse(..config, tools: Some([tool]))
    Some(ts) -> CreateResponse(..config, tools: Some(list.prepend(ts, tool)))
  }
}

pub fn create(
  client client: String,
  request config: CreateResponse,
) -> Result(Response, error.OpenaiError) {
  // I think this assert is Ok
  let assert Ok(base_req) = http_request.to(responses_url)

  let body =
    cr.create_response_encoder(config)
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
    json.parse(resp.body, response.response_decoder())
    // |> echo
    |> result.replace_error(error.BadResponse),
  )

  Ok(result)
}
