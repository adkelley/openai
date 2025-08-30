import gleam/dynamic/decode
import openai/embeddings/types.{EmbeddingObject, EmbeddingObjects, Usage}

fn data_decoder() {
  use object <- decode.field("object", decode.string)
  use index <- decode.field("index", decode.int)
  use embedding <- decode.field("embedding", decode.list(decode.float))
  decode.success(EmbeddingObject(
    object: object,
    embedding: embedding,
    index: index,
  ))
}

fn usage_decoder() {
  use prompt_tokens <- decode.field("prompt_tokens", decode.int)
  use total_tokens <- decode.field("total_tokens", decode.int)
  decode.success(Usage(prompt_tokens:, total_tokens:))
}

pub fn embeddings_decoder() {
  use object <- decode.field("object", decode.string)
  use data <- decode.field("data", decode.list(data_decoder()))
  use model <- decode.field("model", decode.string)
  use usage <- decode.field("usage", usage_decoder())
  decode.success(EmbeddingObjects(
    object: object,
    data: data,
    model: model,
    usage: usage,
  ))
}
