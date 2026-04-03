import gleam/int
import gleam/io
import gleam/list
import openai/client
import openai/embeddings
import openai/error.{type OpenAIError}
import openai/types/embedding

/// Creates a single embedding and echoes the vector payload returned by the API.
pub fn main() -> Result(Nil, OpenAIError) {
  let assert Ok(client) = client.new()

  let request =
    embedding.new()
    |> embedding.with_input(
      embedding.StringList([
        "Why do programmers hate nature? It has too many bugs.",
        "Why was the computer cold? It left its Windows open.",
      ]),
    )

  let assert Ok(response) = embeddings.create(client, request)

  list.fold(response.data, Nil, fn(_acc, data) {
    io.println(
      "["
      <> int.to_string(data.index)
      <> "]: has embedding of length "
      <> int.to_string(list.length(data.embedding)),
    )
  })
  |> Ok()
}
