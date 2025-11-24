/// Streams chat completion deltas and prints them as they arrive.
import envoy
import gleam/io
import gleam/list

import openai/completions
import openai/completions/types
import openai/error
import openai/types as shared

/// Sets up a streaming chat completion request and consumes the events.
pub fn main() -> Result(Nil, error.OpenaiError) {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let prompt = "Why is the sky blue?"
  io.println("Prompt: " <> prompt)

  let config = completions.default_config()
  let messages =
    completions.add_message([], shared.System, "You are a helpful assistant")
    |> completions.add_message(shared.User, prompt)

  let config = types.Config(..config, stream: True)
  io.println("\nStreaming: ")
  let result = completions.stream_create(api_key, config, messages)
  case result {
    Ok(stream_handler) -> loop(stream_handler)
    Error(e) -> Error(e) |> echo
  }
}

// Recursively pulls chunks from the active stream handler until completion.
fn loop(handler: completions.StreamHandler) -> Result(Nil, error.OpenaiError) {
  case completions.stream_create_handler(handler) {
    Ok(completions.StreamChunk(completion_chunks)) -> {
      list.map(completion_chunks, fn(completion) {
        list.map(completion.choices, fn(choice) {
          io.print(choice.delta.content)
        })
      })
      loop(handler)
    }
    Ok(completions.StreamStart(handler_)) -> loop(handler_)
    Ok(completions.StreamEnd) -> {
      io.println("")
      Ok(Nil)
    }
    Error(e) -> Error(e) |> echo
  }
}
