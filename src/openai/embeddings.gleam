import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/option.{type Option}
import gleam/result

import openai/error
import openai/types/embeddings as types

const embeddings_url = "https://api.openai.com/v1/embeddings"

pub const default_model = types.TextEmbeddingAda002

// TODO: Support input arrays
// TODO: Support base64 encoding format
pub fn create(
  client: String,
  input: String,
  model: types.Model,
  dimensions: Option(Int),
  encoding_format: Option(types.EncodingFormat),
  user: Option(String),
) -> Result(types.Objects, error.OpenaiError) {
  // I think this assert is Ok
  let assert Ok(base_req) = request.to(embeddings_url)
  let body = body_encoder(input, model, dimensions, encoding_format, user)
  let req =
    base_req
    |> request.prepend_header("Content-Type", "application/json")
    |> request.prepend_header("Authorization", "Bearer " <> client)
    |> request.set_body(body)
    |> request.set_method(http.Post)

  use resp <- result.try(httpc.send(req) |> error.replace_error())
  use embedding <- result.try(
    json.parse(resp.body, types.objects_decoder())
    |> result.replace_error(error.BadResponse),
  )
  Ok(embedding)
}

// region:    --- Json encoding

fn body_encoder(
  input: String,
  model: types.Model,
  _dimensions: Option(Int),
  encoding_format: Option(types.EncodingFormat),
  _user: Option(String),
) -> String {
  json.object([
    #("input", json.string(input)),
    #("model", json.string(types.model_encoder(model))),
    #(
      "encoding_format",
      json.string(types.encoding_format_encoder(encoding_format)),
    ),
  ])
  |> json.to_string
}
// endregion: --- Json encoding
