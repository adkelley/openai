import envoy
import gleam/io

import openai/responses

pub fn main() -> Nil {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let prompt = "Why is the sky blue?"
  io.println("Prompt: " <> prompt)

  let config = responses.default_request() |> responses.add_input(prompt)

  io.println("\nNo Streaming: ")
  // TODO Should it be the users responsibility to tease out the content from the
  // payload?
  let assert Ok(response) = responses.create(api_key, config)
  echo response

  Nil
}
