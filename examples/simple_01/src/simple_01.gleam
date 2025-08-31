import envoy
import gleam/io
import openai/chat/completions
import openai/chat/types.{Model, System, User}

pub fn main() -> Nil {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  io.println("Prompt: Why is the sky blue?")
  let model = completions.default_model()
  let messages =
    completions.add_message([], System, "You are a helpful assistant")
    |> completions.add_message(User, "Why is the sky blue?")

  io.println("\nNo Streaming: ")
  let _ = completions.create(api_key, model, messages) |> echo

  let model = Model(..model, stream: True)
  let messages =
    completions.add_message([], System, "You are a helpful assistant")
    |> completions.add_message(
      User,
      "Count from 0 to 5 separated by commas, for example 1, 2, 3 ..",
    )
  io.println("\nStreaming: ")
  // TODO WIP this will likely be an 'await next chunk' based approach
  let _ = completions.create_streaming(api_key, model, messages) |> echo
  Nil
}
