/// Requests an embedding for a short piece of text and prints the response.
import envoy
import gleam/io
import gleam/option.{None}
import openai/embeddings
import openai/embeddings/types.{type Objects}
import openai/error.{type OpenaiError}

/// Creates a single embedding and echoes the vector payload returned by the API.
pub fn main() -> Result(Objects, OpenaiError) {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let input = "The food was delicious and the waiter..."
  io.println("Input: " <> input)
  let model = embeddings.default_model
  io.println("Model: " <> types.embedding_model_to_string(model))
  let _ = embeddings.create(api_key, input, model, None, None, None) |> echo
}
