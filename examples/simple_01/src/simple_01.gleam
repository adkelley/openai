import envoy
import gleam/io
import gleam/list

import openai/chat/completions
import openai/chat/types.{Model, System, User}

pub fn main() -> Nil {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let prompt = "Why is the sky blue?"
  // let prompt = "Count from 1 to 5 (e.g., 1, 2, 3, ...)"
  io.println("Prompt: " <> prompt)

  let model = completions.default_model()
  let messages =
    completions.add_message([], System, "You are a helpful assistant")
    |> completions.add_message(User, prompt)

  io.println("\nNo Streaming: ")
  // It's the users responsibility to tease out the content from the
  // payload
  let assert Ok(completion) = completions.create(api_key, model, messages)
  let content =
    list.fold(completion.choices, "", fn(acc, choice) {
      acc <> choice.message.content
    })
  io.println(content)

  let model = Model(..model, stream: True)
  io.println("\nStreaming: ")
  let assert Ok(_) = completions.async_create(api_key, model, messages)

  Nil
}
