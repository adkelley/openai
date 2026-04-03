import gleam/io
import openai/audio
import openai/client
import openai/error.{type OpenAIError}
import openai/types/audio/transcription

pub fn main() -> Result(Nil, OpenAIError) {
  let assert Ok(client) = client.new()
  let filename = "./audio/transcription.m4a"

  let assert Ok(transcript) =
    transcription.new()
    |> transcription.with_file(filename)
    |> audio.create_transcription(client, _)

  io.println("\nDefault")
  io.println("Text: " <> transcript.text)

  io.println("\nDiarized")
  io.println("Text: " <> transcript.text)

  Ok(Nil)
}
