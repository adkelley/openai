import envoy
import gleam/bit_array
import gleam/dynamic/decode as decode
import gleam/json
import gleam/option.{type Option}
import gleam/result
import openai/error.{
  type OpenAIError, Authentication, BadResponse, InternalServer,
  InvalidRequest, NotFound, RateLimit, TokensExceeded, Unknown,
}
import openai/transport as openai_transport

pub type Client {
  Client(config: String, transport: openai_transport.Transport)
}

pub fn new() -> Result(Client, OpenAIError) {
  use api_key <- result.try(
    envoy.get("OPENAI_API_KEY")
    |> result.replace_error(Authentication("Unset OPENAI_API_KEY")),
  )

  Ok(from_api_key(api_key))
}

pub fn from_api_key(api_key: String) -> Client {
  Client(config: api_key, transport: openai_transport.httpc_transport())
}

pub fn with_transport(
  client: Client,
  transport: openai_transport.Transport,
) -> Client {
  Client(..client, transport:)
}

pub fn new_with_transport(
  api_key: String,
  transport: openai_transport.Transport,
) -> Client {
  from_api_key(api_key)
  |> with_transport(transport)
}

pub fn send_text(
  client: Client,
  method: openai_transport.Method,
  url: String,
  headers: List(#(String, String)),
  body: String,
  timeout_ms: Option(Int),
) -> Result(String, OpenAIError) {
  use response <- result.try(send(
    client,
    method,
    url,
    headers,
    openai_transport.Text(body),
    timeout_ms,
  ))
  response_to_text(response)
}

pub fn send_bytes(
  client: Client,
  method: openai_transport.Method,
  url: String,
  headers: List(#(String, String)),
  body: BitArray,
  timeout_ms: Option(Int),
) -> Result(openai_transport.Body, OpenAIError) {
  use response <- result.try(send(
    client,
    method,
    url,
    headers,
    openai_transport.Bytes(body),
    timeout_ms,
  ))
  let openai_transport.TransportResponse(body: body, ..) = response
  Ok(body)
}

pub fn start_stream(
  client: Client,
  method: openai_transport.Method,
  url: String,
  headers: List(#(String, String)),
  body: String,
  timeout_ms: Option(Int),
) -> Result(openai_transport.Stream, OpenAIError) {
  let Client(config:, transport:) = client
  openai_transport.start_stream(transport, openai_transport.TransportRequest(
    method: method,
    url: url,
    headers: add_auth_header(config, headers),
    body: openai_transport.Text(body),
    timeout_ms: timeout_ms,
  ))
}

fn send(
  client: Client,
  method: openai_transport.Method,
  url: String,
  headers: List(#(String, String)),
  body: openai_transport.Body,
  timeout_ms: Option(Int),
) -> Result(openai_transport.TransportResponse, OpenAIError) {
  let Client(config:, transport:) = client
  use response <- result.try(
    openai_transport.send(transport, openai_transport.TransportRequest(
    method: method,
    url: url,
    headers: add_auth_header(config, headers),
    body: body,
    timeout_ms: timeout_ms,
  )),
  )
  map_http_response(response)
}

fn add_auth_header(
  api_key: String,
  headers: List(#(String, String)),
) -> List(#(String, String)) {
  [#("Authorization", "Bearer " <> api_key), ..headers]
}

fn map_http_response(
  response: openai_transport.TransportResponse,
) -> Result(openai_transport.TransportResponse, OpenAIError) {
  let openai_transport.TransportResponse(status, _headers, body) = response
  case status {
    200 -> Ok(response)
    400 -> error_with_message(InvalidRequest, body)
    401 -> error_with_message(Authentication, body)
    403 -> error_with_message(TokensExceeded, body)
    404 -> error_with_message(NotFound, body)
    429 -> error_with_message(RateLimit, body)
    500 -> error_with_message(InternalServer, body)
    _ -> Error(Unknown)
  }
}

fn response_to_text(
  response: openai_transport.TransportResponse,
) -> Result(String, OpenAIError) {
  let openai_transport.TransportResponse(_status, _headers, body) = response
  case body {
    openai_transport.Text(body) -> Ok(body)
    openai_transport.Bytes(body) ->
      bit_array.to_string(body) |> result.replace_error(BadResponse)
  }
}

fn error_with_message(
  constructor: fn(String) -> OpenAIError,
  body: openai_transport.Body,
) -> Result(openai_transport.TransportResponse, OpenAIError) {
  use body <- result.try(response_body_to_string(body))
  use message <- result.try(parse_error_message(body))
  Error(constructor(message))
}

fn response_body_to_string(body: openai_transport.Body) -> Result(String, OpenAIError) {
  case body {
    openai_transport.Text(body) -> Ok(body)
    openai_transport.Bytes(body) ->
      bit_array.to_string(body) |> result.replace_error(BadResponse)
  }
}

fn parse_error_message(body: String) -> Result(String, OpenAIError) {
  let error_message_decoder = fn() {
    use message <- decode.subfield(["error", "message"], decode.string)
    decode.success(message)
  }

  json.parse(body, error_message_decoder())
  |> result.replace_error(BadResponse)
}
