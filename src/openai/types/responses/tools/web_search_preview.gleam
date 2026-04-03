import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import openai/types/helpers
import openai/types/responses/tools/search_context_size.{type SearchContextSize}
import openai/types/responses/tools/user_location.{type UserLocation}

pub type WebSearchPreview {
  WebSearchPreview(
    // type: "web_search_preview" or "web_search_preview_2025_03_11"
    /// High level guidance for the amount of context window space to use for
    /// the search. One of low, medium, or high. medium is the default.
    search_context_size: Option(SearchContextSize),
    /// The approximate location of the user.
    user_location: Option(UserLocation),
  )
}

pub fn new() -> WebSearchPreview {
  WebSearchPreview(search_context_size: None, user_location: None)
}

pub fn user_location(
  web_search_preview: WebSearchPreview,
  user_location: UserLocation,
) -> WebSearchPreview {
  WebSearchPreview(..web_search_preview, user_location: Some(user_location))
}

pub fn search_context_size(
  web_search: WebSearchPreview,
  search_context_size: SearchContextSize,
) -> WebSearchPreview {
  WebSearchPreview(..web_search, search_context_size: Some(search_context_size))
}

pub fn encode_web_search_preview(web_search_preview: WebSearchPreview) -> Json {
  [
    #("type", json.string("web_search_preview")),
  ]
  |> helpers.encode_option(
    "user_location",
    web_search_preview.user_location,
    user_location.encode_user_location,
  )
  |> helpers.encode_option(
    "search_context_size",
    web_search_preview.search_context_size,
    search_context_size.encode_search_context_size,
  )
  |> json.object
}

pub fn decode_web_search_preview() -> Decoder(WebSearchPreview) {
  use search_context_size <- decode.field(
    "search_context_size",
    decode.optional(search_context_size.decode_search_context_size()),
  )
  use user_location <- decode.field(
    "user_location",
    decode.optional(user_location.decode_user_location()),
  )
  decode.success(WebSearchPreview(search_context_size:, user_location:))
}
