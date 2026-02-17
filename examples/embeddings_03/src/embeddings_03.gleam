/// Requests an embedding for a short piece of text and prints the response.
import envoy
import gleam/io
import gleam/option.{None}
import openai/embeddings as e
import openai/error.{type OpenaiError}
import openai/types/embeddings.{type Objects}

/// Creates a single embedding and echoes the vector payload returned by the API.
pub fn main() -> Result(Objects, OpenaiError) {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let input = "The food was delicious and the waiter..."
  io.println("Input: " <> input)
  let model = e.default_model
  io.println("Model: " <> embeddings.model_encoder(model))
  let _ = e.create(api_key, input, model, None, None, None) |> echo
}
