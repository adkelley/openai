/// Issues a single chat completion request and prints the assistant response.
import gleam/io
import gleam/list
import openai/client
import openai/completions
import openai/error.{type OpenAIError}
import openai/types/completion
import openai/types/role.{System, User}

/// Sends a prompt to the Chat Completions API and writes the reply to stdout.
pub fn main() -> Result(Nil, OpenAIError) {
  let assert Ok(client) = client.new()

  let prompt = "Why is the sky blue?"
  io.println("\nPrompt: " <> prompt)

  let config = completion.new()
  let messages =
    completions.add_message([], System, "You are a helpful assistant")
    |> completions.add_message(User, prompt)

  io.println("No Streaming (typed response): ")
  let assert Ok(chat_completion) = completions.create(client, config, messages)
  list.fold(chat_completion.choices, "", fn(acc, choice) {
    acc <> choice.message.content
  })
  |> io.println()

  let prompt = "Give me a three paragraph poem about rain."
  let config = completion.new()
  let messages =
    completions.add_message([], System, "You are a helpful assistant")
    |> completions.add_message(User, prompt)

  io.println("\nPrompt: " <> prompt)
  io.println("No Streaming (custom decoder): ")
  let assert Ok(messages) =
    completions.create_with_decoder(
      client,
      config,
      messages,
      completion.decode_messages(),
    )

  list.fold(messages, "", fn(acc, message) { acc <> message.content })
  |> io.println()

  Ok(Nil)
}
