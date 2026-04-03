import gleam/dynamic/decode
import gleam/json.{type Json}

pub type Role {
  Assistant
  User
  Developer
  System
}

pub fn encode_role(role: Role) -> Json {
  case role {
    Assistant -> "assistant"
    User -> "user"
    Developer -> "developer"
    System -> "system"
  }
  |> json.string
}

pub fn decode_role() {
  use role_string <- decode.then(decode.string)
  case role_string {
    "assistant" -> decode.success(Assistant)
    "user" -> decode.success(User)
    "system" -> decode.success(System)
    "developer" -> decode.success(Developer)
    _ -> panic as role_string
  }
}
