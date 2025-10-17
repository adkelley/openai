import envoy
import gleam/io

import openai/completions
import openai/completions/types
import openai/types as shared

pub fn main() -> Nil {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let prompt = "Why is the sky blue?"
  io.println("Prompt: " <> prompt)

  let config = completions.default_config()
  let messages =
    completions.add_message([], shared.System, "You are a helpful assistant")
    |> completions.add_message(shared.User, prompt)

  let config = types.Config(..config, stream: True)
  io.println("\nStreaming: ")
  let assert Ok(_) = completions.stream_create(api_key, config, messages)

  Nil
}
