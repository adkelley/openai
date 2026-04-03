import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}

pub type SearchContextSize {
  Low
  Medium
  High
}

pub fn encode_search_context_size(
  search_context_size: SearchContextSize,
) -> Json {
  case search_context_size {
    Low -> "low"
    Medium -> "medium"
    High -> "high"
  }
  |> json.string
}

pub fn decode_search_context_size() -> Decoder(SearchContextSize) {
  decode.string
  |> decode.map(fn(size) {
    case size {
      "low" -> Low
      "medium" -> Medium
      "high" -> High
      _ -> panic as size
    }
  })
}
