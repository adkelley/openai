import gleam/json.{type Json}

/// The role of a message
pub type Role {
  System
  User
  Assistant
  Tool
  OtherRole(String)
}

pub fn role_encoder(role: Role) -> Json {
  case role {
    Assistant -> "assistant"
    OtherRole(str) -> str
    System -> "system"
    Tool -> "tool"
    User -> "user"
  }
  |> json.string
}

/// The model to use for generating a response.
pub type Model {
  O1
  O1Mini
  O1Pro
  O3Mini
  GPT45Preview
  GPT41
  GPT41Mini
  GPT4o
  GPT4oMini
  GPT4Turbo
  GPT4
  GPT5
  GPT51
  GPT52
  GPT5Mini
  GPT5Nano
  GPT35Turbo
  ComputerUsePreview
  Other(String)
}

pub fn model_encoder(model: Model) -> Json {
  case model {
    ComputerUsePreview -> "computer-use-preview"
    GPT35Turbo -> "gpt-3.5-turbo"
    GPT4 -> "gpt-4o"
    GPT41 -> "gpt-4.1"
    GPT45Preview -> "gpt-4.5-preview"
    GPT4Turbo -> "gpt-4o-turbo"
    GPT4o -> "gpt-4o"
    GPT4oMini -> "gpt-4o-mini"
    GPT41Mini -> "gpt-4.1-mini"
    GPT5 -> "gpt-5"
    GPT51 -> "gpt-5.1"
    GPT52 -> "gpt-5.2"
    GPT5Mini -> "gpt-5-mini"
    GPT5Nano -> "gpt-5-nano"
    O1 -> "o1"
    O1Mini -> "o1-mini"
    O1Pro -> "o1-pro"
    O3Mini -> "o3-mini"
    Other(str) -> str
  }
  |> json.string
}
