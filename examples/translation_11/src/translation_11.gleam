import gleam/io
import openai/audio
import openai/client
import openai/error.{type OpenAIError}
import openai/types/audio/translation

pub fn main() -> Result(Nil, OpenAIError) {
  let assert Ok(client) = client.new()
  let filename = "./audio/japanese_speech.m4a"

  let assert Ok(transcript) =
    translation.new()
    |> translation.with_file(filename)
    |> audio.create_translation(client, _)

  io.println("\nDefault")
  io.println("Text: " <> transcript.text)

  Ok(Nil)
}
