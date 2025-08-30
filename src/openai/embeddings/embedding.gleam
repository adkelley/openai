import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/result

import openai/embeddings/types.{
  type EmbeddingModel, type EmbeddingObjects, type EncodingFormat,
  TextEmbedding3Large, TextEmbedding3Small, TextEmbeddingAda002,
}

import openai/embeddings/decoder
import openai/error.{type OpenaiError, BadResponse}

const embeddings_url = "https://api.openai.com/v1/embeddings"

pub const default_model = TextEmbeddingAda002

pub fn embedding_model_to_string(model: EmbeddingModel) -> String {
  case model {
    TextEmbedding3Large -> "text-embedding-3-large"
    TextEmbedding3Small -> "text-embedding-3-small"
    TextEmbeddingAda002 -> "text-embedding-ada-002"
  }
}

fn encoding_format_to_string(format: Option(EncodingFormat)) -> String {
  case format {
    None -> "float"
    Some(types.Float) -> "float"
    Some(types.Base64) -> {
      echo "Base64 not supported"
      panic
    }
  }
}

// TODO: Support input arrays
// TODO: Support base64 encoding format
pub fn create(
  client: String,
  input: String,
  model: EmbeddingModel,
  dimensions: Option(Int),
  encoding_format: Option(EncodingFormat),
  user: Option(String),
) -> Result(EmbeddingObjects, OpenaiError) {
  // I think this assert is Ok
  let assert Ok(base_req) = request.to(embeddings_url)
  let body =
    body_to_json_string(input, model, dimensions, encoding_format, user)
  let req =
    base_req
    |> request.prepend_header("Content-Type", "application/json")
    |> request.prepend_header("Authorization", "Bearer " <> client)
    |> request.set_body(body)
    |> request.set_method(http.Post)

  use resp <- result.try(httpc.send(req) |> error.replace_error())
  use embedding <- result.try(
    json.parse(resp.body, decoder.embeddings_decoder())
    |> result.replace_error(BadResponse),
  )
  Ok(embedding)
}

// region:    --- Json encoding

fn body_to_json_string(
  input: String,
  model: EmbeddingModel,
  _dimensions: Option(Int),
  encoding_format: Option(EncodingFormat),
  _user: Option(String),
) -> String {
  json.object([
    #("input", json.string(input)),
    #("model", json.string(embedding_model_to_string(model))),
    #(
      "encoding_format",
      json.string(encoding_format_to_string(encoding_format)),
    ),
  ])
  |> json.to_string
}
// endregion: --- Json encoding
