import envoy
import gleam/io

import openai/chat/completions
import openai/chat/types
import openai/shared/types as shared

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
