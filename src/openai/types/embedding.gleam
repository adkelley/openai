import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import openai/types/helpers

const model_ada_002 = "text-embedding-ada-002"

/// https://platform.openai.com/docs/api-reference/embeddings/create
///
pub type EmbeddingCreateParams {
  EmbeddingCreateParams(
    input: EmbeddingInput,
    model: String,
    dimensions: Option(Int),
    encoding_format: Option(EncodingFormat),
    user: Option(String),
  )
}

pub fn new() -> EmbeddingCreateParams {
  EmbeddingCreateParams(
    input: StringList([]),
    model: model_ada_002,
    dimensions: None,
    encoding_format: None,
    user: None,
  )
}

pub fn with_input(
  embedding: EmbeddingCreateParams,
  input: EmbeddingInput,
) -> EmbeddingCreateParams {
  EmbeddingCreateParams(..embedding, input: input)
}

pub fn with_dimensions(
  embedding: EmbeddingCreateParams,
  dimensions: Int,
) -> EmbeddingCreateParams {
  EmbeddingCreateParams(..embedding, dimensions: Some(dimensions))
}

pub fn with_encoding_format(
  embedding: EmbeddingCreateParams,
  encoding_format: EncodingFormat,
) -> EmbeddingCreateParams {
  EmbeddingCreateParams(..embedding, encoding_format: Some(encoding_format))
}

pub fn with_user(
  embedding: EmbeddingCreateParams,
  user: String,
) -> EmbeddingCreateParams {
  EmbeddingCreateParams(..embedding, user: Some(user))
}

pub fn encode_embedding_create_params(
  create_params: EmbeddingCreateParams,
) -> Json {
  [
    #("input", encode_embedding_input(create_params.input)),
    #("model", json.string(create_params.model)),
  ]
  |> helpers.encode_option(
    "encoding_format",
    create_params.encoding_format,
    encode_encoding_format,
  )
  |> helpers.encode_option("dimensions", create_params.dimensions, json.int)
  |> helpers.encode_option("user", create_params.user, json.string)
  |> json.object
}

// TODO support Array<string>, etc.
pub type EmbeddingInput {
  String(String)
  StringList(List(String))
  IntegerList(List(Int))
  ListOfIntegerList(List(List(Int)))
}

pub fn encode_embedding_input(input: EmbeddingInput) -> Json {
  case input {
    String(x) -> json.string(x)
    StringList(xs) -> json.array(xs, json.string)
    IntegerList(xi) -> json.array(xi, json.int)
    ListOfIntegerList(xi) -> json.array(xi, fn(x) { json.array(x, json.int) })
  }
}

pub type CreateEmbeddingResponse {
  CreateEmbeddingResponse(
    data: List(Embedding),
    model: String,
    // object: "list"
    usage: Usage,
  )
}

pub fn decode_create_embedding_response() -> Decoder(CreateEmbeddingResponse) {
  use object <- decode.field("object", decode.string)
  assert object == "list"

  use data <- decode.field("data", decode.list(decode_embedding()))
  use model <- decode.field("model", decode.string)
  use usage <- decode.field("usage", decode_usage())
  decode.success(CreateEmbeddingResponse(data:, model:, usage:))
}

pub type Embedding {
  Embedding(
    embedding: List(Float),
    index: Int,
    // object: "embedding"
  )
}

fn decode_embedding() -> Decoder(Embedding) {
  use object <- decode.field("object", decode.string)
  assert object == "embedding"

  use embedding <- decode.field("embedding", decode.list(decode.float))
  use index <- decode.field("index", decode.int)

  decode.success(Embedding(embedding:, index:))
}

pub type Object {
  Object(object: String, embedding: List(Float), index: Int)
}

fn decode_object() {
  use object <- decode.field("object", decode.string)
  use index <- decode.field("index", decode.int)
  use embedding <- decode.field("embedding", decode.list(decode.float))
  decode.success(Object(object: object, embedding: embedding, index: index))
}

// Usage breakdown
pub type Usage {
  Usage(prompt_tokens: Int, total_tokens: Int)
}

fn decode_usage() {
  use prompt_tokens <- decode.field("prompt_tokens", decode.int)
  use total_tokens <- decode.field("total_tokens", decode.int)
  decode.success(Usage(prompt_tokens:, total_tokens:))
}

pub type Objects {
  Objects(object: String, data: List(Object), model: String, usage: Usage)
}

pub fn decode_objects() {
  use object <- decode.field("object", decode.string)
  use data <- decode.field("data", decode.list(decode_object()))
  use model <- decode.field("model", decode.string)
  use usage <- decode.field("usage", decode_usage())

  decode.success(Objects(object: object, data: data, model: model, usage: usage))
}

pub type EncodingFormat {
  // TODO Support this format
  // Base64
  Float
}

pub fn encoding_format_from_string(format: String) -> EncodingFormat {
  case format {
    "float" -> Float
    _ -> panic as "EncodingFormat unsupported"
  }
}

fn encoding_format_to_string(format: EncodingFormat) -> String {
  case format {
    Float -> "float"
  }
}

pub fn encode_encoding_format(format: EncodingFormat) -> Json {
  encoding_format_to_string(format) |> json.string
}
