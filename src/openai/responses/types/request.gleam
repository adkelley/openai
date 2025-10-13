import gleam/option.{type Option}
import openai/shared/types as shared

pub type Request {
  Request(
    model: shared.Model,
    input: Input,
    temperature: Option(Float),
    stream: Option(Bool),
    // tools: Tools
  )
}

pub type Input {
  Text(String)
}
