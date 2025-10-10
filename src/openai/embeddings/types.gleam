// https://platform.openai.com/docs/api-reference/embeddings/create
// 
// Represents an embedding vector returned by embedding endpoint.
// 
import gleam/option.{type Option, None, Some}

pub type Embedding =
  Float

pub type Object {
  Object(object: String, embedding: List(Embedding), index: Int)
}

// Usage breakdown
pub type Usage {
  Usage(prompt_tokens: Int, total_tokens: Int)
}

pub type Objects {
  Objects(object: String, data: List(Object), model: String, usage: Usage)
}

// https://platform.openai.com/docs/guides/embeddings#embedding-models
pub type Model {
  TextEmbedding3Large
  TextEmbedding3Small
  TextEmbeddingAda002
}

pub fn embedding_model_to_string(model: Model) -> String {
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

pub fn encoding_format_to_string(format: Option(EncodingFormat)) -> String {
  case format {
    None -> "float"
    Some(Float) -> "float"
    Some(Base64) -> {
      echo "Base64 not supported"
      panic
    }
  }
}
