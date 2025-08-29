import chat/completions
import chat/types.{type OpenaiError, Model, System, User}
import envoy
import gleam/io

pub fn main() -> Result(String, OpenaiError) {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  io.println("Prompt: Why is the sky blue?")
  let model = completions.default_model()
  let messages =
    completions.add_message([], System, "You are a helpful assistant")
    |> completions.add_message(User, "Why is the sky blue?")

  io.println("\nNo Streaming: ")
  let _ = completions.create(api_key, model, messages) |> echo

  io.println("\nStreaming: ")
  let model = Model(..model, stream: True)
  completions.create(api_key, model, messages) |> echo
}
