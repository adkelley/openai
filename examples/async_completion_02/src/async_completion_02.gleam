/// Streams chat completion deltas and prints them as they arrive.
import envoy
import gleam/io
import gleam/list

import openai/completions as c
import openai/error
import openai/types/completions.{Config}
import openai/types/shared.{System, User}

/// Sets up a streaming chat completion request and consumes the events.
pub fn main() -> Result(Nil, error.OpenaiError) {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let prompt = "Why is the sky blue?"
  io.println("Prompt: " <> prompt)

  let config = c.default_config()
  let messages =
    c.add_message([], System, "You are a helpful assistant")
    |> c.add_message(User, prompt)

  let config = Config(..config, stream: True)
  io.println("\nStreaming: ")
  let result = c.stream_create(api_key, config, messages)
  case result {
    Ok(stream_handler) -> loop(stream_handler)
    Error(e) -> Error(e) |> echo
  }
}

// Recursively pulls chunks from the active stream handler until completion.
fn loop(handler: c.StreamHandler) -> Result(Nil, error.OpenaiError) {
  case c.stream_create_handler(handler) {
    Ok(c.StreamChunk(completion_chunks)) -> {
      list.map(completion_chunks, fn(completion) {
        list.map(completion.choices, fn(choice) {
          io.print(choice.delta.content)
        })
      })
      loop(handler)
    }
    Ok(c.StreamStart(handler_)) -> loop(handler_)
    Ok(c.StreamEnd) -> {
      io.println("")
      Ok(Nil)
    }
    Error(e) -> Error(e) |> echo
  }
}
