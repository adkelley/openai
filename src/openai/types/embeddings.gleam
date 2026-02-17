import gleam/dynamic/decode
import gleam/option.{type Option, None, Some}

// https://platform.openai.com/docs/api-reference/embeddings/create
// 
// Represents an embedding vector returned by embedding endpoint.
// 
pub type Embedding =
  Float

pub type Object {
  Object(object: String, embedding: List(Embedding), index: Int)
}

fn object_decoder() {
  use object <- decode.field("object", decode.string)
  use index <- decode.field("index", decode.int)
  use embedding <- decode.field("embedding", decode.list(decode.float))
  decode.success(Object(object: object, embedding: embedding, index: index))
}

// Usage breakdown
pub type Usage {
  Usage(prompt_tokens: Int, total_tokens: Int)
}

fn usage_decoder() {
  use prompt_tokens <- decode.field("prompt_tokens", decode.int)
  use total_tokens <- decode.field("total_tokens", decode.int)
  decode.success(Usage(prompt_tokens:, total_tokens:))
}

pub type Objects {
  Objects(object: String, data: List(Object), model: String, usage: Usage)
}

pub fn objects_decoder() {
  use object <- decode.field("object", decode.string)
  use data <- decode.field("data", decode.list(object_decoder()))
  use model <- decode.field("model", decode.string)
  use usage <- decode.field("usage", usage_decoder())
  decode.success(Objects(object: object, data: data, model: model, usage: usage))
}

// https://platform.openai.com/docs/guides/embeddings#embedding-models
pub type Model {
  TextEmbedding3Large
  TextEmbedding3Small
  TextEmbeddingAda002
}

pub fn model_encoder(model: Model) -> String {
  case model {
    TextEmbedding3Large -> "text-embedding-3-large"
    TextEmbedding3Small -> "text-embedding-3-small"
    TextEmbeddingAda002 -> "text-embedding-ada-002"
  }
}

pub type EncodingFormat {
  Base64
  Float
}

pub fn encoding_format_encoder(format: Option(EncodingFormat)) -> String {
  case format {
    None -> "float"
    Some(Float) -> "float"
    Some(Base64) -> {
      echo "Base64 not supported"
      panic
    }
  }
}
