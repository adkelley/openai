import chat/completions
import chat/types.{System, User}
import envoy
import gleam/io

pub fn main() -> Nil {
  io.println("Prompt: Why is the sky blue?")
  let model = completions.default_model()
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")
  let messages =
    completions.add_message([], System, "You are a helpful assistant")
    |> completions.add_message(User, "Why is the sky blue?")

  completions.create(api_key, model, messages) |> echo
  Nil
}
