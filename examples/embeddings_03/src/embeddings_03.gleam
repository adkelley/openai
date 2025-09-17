import envoy
import gleam/io
import gleam/option.{None}
import openai/embeddings/embedding
import openai/embeddings/types.{type EmbeddingObjects}
import openai/error.{type OpenaiError}

pub fn main() -> Result(EmbeddingObjects, OpenaiError) {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let input = "The food was delicious and the waiter..."
  io.println("Input: " <> input)
  let model = embedding.default_model
  io.println("Model: " <> embedding.embedding_model_to_string(model))
  let _ = embedding.create(api_key, input, model, None, None, None) |> echo
}
