/// Streams chat completion deltas and prints them as they arrive.
import openai/client

import gleam/dynamic/decode
import gleam/io
import gleam/list

import openai/completions
import openai/error.{type OpenAIError}
import openai/types/completion

import openai/types/role.{System, User}

/// Sets up a streaming chat completion request and consumes the events.
pub fn main() -> Result(Nil, OpenAIError) {
  let assert Ok(client) = client.new()

  let prompt = "Why is the sky blue?"
  io.println("Prompt: " <> prompt)

  let config = completion.new() |> completion.with_stream(True)

  let messages =
    completions.add_message([], System, "You are a helpful assistant")
    |> completions.add_message(User, prompt)

  io.println("\nStreaming: ")
  let result = completions.stream_create(client, config, messages)
  case result {
    Ok(stream_handler) -> loop(stream_handler)
    Error(e) -> Error(e)
  }
}

// Recursively pulls and prints chunks from the active stream handler until completion.
fn loop(handler: completions.StreamHandler) -> Result(Nil, OpenAIError) {
  case
    completions.stream_create_handler_with_decoder(
      handler,
      decode_first_completion_chunk_text(),
    )
  {
    Ok(completions.DecodedStreamChunk(text_chunks)) -> {
      list.map(text_chunks, fn(text) { io.print(text) })
      loop(handler)
    }
    Ok(completions.DecodedStreamStart(handler_)) -> loop(handler_)
    Ok(completions.DecodedStreamEnd) -> {
      io.println("")
      Ok(Nil)
    }
    Error(e) -> Error(e)
  }
}

fn decode_first_completion_chunk_text() -> decode.Decoder(String) {
  let decode_first_choice = fn() {
    use content <- decode.subfield(["delta", "content"], decode.string)
    decode.success(content)
  }

  decode.at(["choices"], decode.at([0], decode_first_choice()))
}
