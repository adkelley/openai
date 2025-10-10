/// The role of a message
pub type Role {
  System
  User
  Assistant
  Tool
  OtherRole(String)
}

/// The model to use for generating a response.
pub type Model {
  O1
  O1Mini
  O1Pro
  O3Mini
  GPT45Preview
  GPT41Mini
  GPT4o
  GPT4oMini
  GPT4Turbo
  GPT4
  GPT35Turbo
  ComputerUsePreview
  Other(String)
}

pub fn describe_model(model: Model) -> String {
  case model {
    ComputerUsePreview -> "computer-use-preview"
    GPT35Turbo -> "gpt-3.5-turbo"
    GPT4 -> "gpt-4o"
    GPT45Preview -> "gpt-4.5-preview"
    GPT4Turbo -> "gpt-4o-turbo"
    GPT4o -> "gpt-4o"
    GPT4oMini -> "gpt-4o-mini"
    GPT41Mini -> "gpt-4.1-mini"
    O1 -> "o1"
    O1Mini -> "o1-mini"
    O1Pro -> "o1-pro"
    O3Mini -> "o3-mini"
    Other(str) -> str
  }
}
