import chat/completions
import envoy
import gleam/io

pub fn main() -> Nil {
  io.println("Hello from simple_01!")
  let model = completions.new()
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")
  let prompt = "Why is the sky blue"

  completions.create(api_key, model, prompt) |> echo
  Nil
}
