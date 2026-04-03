import gleam/json
import gleam/option.{None}
import gleam/result
import openai/client.{type Client}
import openai/transport
import openai/types/embedding.{
  type CreateEmbeddingResponse, type EmbeddingCreateParams,
}

import openai/error.{type OpenAIError}

const embeddings_url = "https://api.openai.com/v1/embeddings"

// TODO: Support input arrays
// TODO: Support base64 encoding format
pub fn create(
  client: Client,
  embedding: EmbeddingCreateParams,
) -> Result(CreateEmbeddingResponse, OpenAIError) {
  let body =
    embedding.encode_embedding_create_params(embedding) |> json.to_string

  use response <- result.try(client.send_text(
    client,
    transport.Post,
    embeddings_url,
    [#("Content-Type", "application/json")],
    body,
    None,
  ))
  use embedding <- result.try(
    json.parse(response, embedding.decode_create_embedding_response())
    |> result.replace_error(error.BadResponse),
  )
  Ok(embedding)
}
