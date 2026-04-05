/// Issues a single chat completion request and prints the assistant response.
import gleam/dynamic/decode
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
  io.println("\nPrompt: " <> prompt)

  let config = completion.new()
  let messages =
    completions.add_message([], System, "You are a helpful assistant")
    |> completions.add_message(User, prompt)

  io.println("No Streaming (typed response): ")
  let assert Ok(chat_completion) = completions.create(client, config, messages)
  let content =
    chat_completion.choices
    |> extract_content
  io.println(content)

  let prompt = "Give me a three paragraph poem about rain."
  let config = completion.new()
  let messages =
    completions.add_message([], System, "You are a helpful assistant")
    |> completions.add_message(User, prompt)

  io.println("\nPrompt: " <> prompt)
  io.println("No Streaming (custom decoder): ")
  let assert Ok(content) =
    completions.create_with_decoder(
      client,
      config,
      messages,
      decode_first_chat_completion_text(),
    )
  io.println(content)

  Nil
}

fn extract_content(choices: List(completion.CompletionChoice)) -> String {
  choices
  |> list.fold("", fn(acc, choice) { acc <> choice.message.content })
}

fn decode_first_chat_completion_text() -> decode.Decoder(String) {
  let decode_first_choice = fn() {
    use content <- decode.subfield(["message", "content"], decode.string)
    decode.success(content)
  }

  decode.at(["choices"], decode.at([0], decode_first_choice()))
}
