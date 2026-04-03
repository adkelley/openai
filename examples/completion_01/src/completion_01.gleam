/// Issues a single chat completion request and prints the assistant response.
import gleam/io
import gleam/list

import openai/client
import openai/completions
import openai/types/completion
import openai/types/role.{System, User}

/// Sends a prompt to the Chat Completions API and writes the reply to stdout.
pub fn main() -> Nil {
  let assert Ok(client) = client.new()

  let prompt = "Why is the sky blue?"
  io.println("Prompt: " <> prompt)

  let config = completion.new()
  let messages =
    completions.add_message([], System, "You are a helpful assistant")
    |> completions.add_message(User, prompt)

  io.println("\nNo Streaming: ")
  // TODO Should it be the users responsibility to tease out the content from the
  // payload?
  let assert Ok(completion) = completions.create(client, config, messages)
  let content =
    list.fold(completion.choices, "", fn(acc, choice) {
      acc <> choice.message.content
    })
  io.println(content)

  Nil
}
