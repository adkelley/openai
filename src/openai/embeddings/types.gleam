// https://platform.openai.com/docs/api-reference/embeddings/create
// 
// Represents an embedding vector returned by embedding endpoint.
pub type Embedding =
  Float

pub type EmbeddingObject {
  EmbeddingObject(object: String, embedding: List(Embedding), index: Int)
}

// Usage breakdown
pub type Usage {
  Usage(prompt_tokens: Int, total_tokens: Int)
}

pub type EmbeddingObjects {
  EmbeddingObjects(
    object: String,
    data: List(EmbeddingObject),
    model: String,
    usage: Usage,
  )
}

// https://duckduckgo.com/?q=openai+api+embedding+models&atb=v351-1&ia=web&assist=true
pub type EmbeddingModel {
  TextEmbedding3Large
  TextEmbedding3Small
  TextEmbeddingAda002
}

pub type EncodingFormat {
  Base64
  Float
}
