import envoy
import gleam/io

import openai/chat/completions
import openai/chat/types.{Model, System, User}

pub fn main() -> Nil {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let prompt = "Why is the sky blue?"
  io.println("Prompt: " <> prompt)

  let model = completions.default_model()
  let messages =
    completions.add_message([], System, "You are a helpful assistant")
    |> completions.add_message(User, prompt)

  let model = Model(..model, stream: True)
  io.println("\nStreaming: ")
  let assert Ok(_) = completions.async_create(api_key, model, messages)

  Nil
}
