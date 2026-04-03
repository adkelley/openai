import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}

pub fn encode_option(
  object: List(#(String, Json)),
  s: String,
  option_value: Option(a),
  f: fn(a) -> Json,
) -> List(#(String, Json)) {
  case option_value {
    Some(a) -> list.prepend(object, #(s, f(a)))

    None -> object
  }
}

pub fn encode_option_list(
  object: List(#(String, Json)),
  s: String,
  option_values: Option(List(a)),
  f: fn(a) -> Json,
) -> List(#(String, Json)) {
  case option_values {
    Some(xs) -> list.prepend(object, #(s, json.array(xs, f)))

    None -> object
  }
}
