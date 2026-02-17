/// Issues a single chat completion request and prints the assistant response.
import envoy
import gleam/io
import gleam/list

import openai/completions
import openai/types/shared.{System, User}

/// Sends a prompt to the Chat Completions API and writes the reply to stdout.
pub fn main() -> Nil {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let prompt = "Why is the sky blue?"
  io.println("Prompt: " <> prompt)

  let config = completions.default_config()
  let messages =
    completions.add_message([], System, "You are a helpful assistant")
    |> completions.add_message(User, prompt)

  io.println("\nNo Streaming: ")
  // TODO Should it be the users responsibility to tease out the content from the
  // payload?
  let assert Ok(completion) = completions.create(api_key, config, messages)
  let content =
    list.fold(completion.choices, "", fn(acc, choice) {
      acc <> choice.message.content
    })
  io.println(content)

  Nil
}
