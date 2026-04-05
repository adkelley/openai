/// Issues a Responses API call configured to use the web search tool.
import gleam/dynamic/decode
import gleam/io
import gleam/option.{type Option, None, Some}
import openai/client
import openai/error.{type OpenAIError}
import openai/responses
import openai/types/responses/response
import openai/types/responses/tool
import openai/types/responses/tools/search_context_size
import openai/types/responses/tools/user_location
import openai/types/responses/tools/web_search

/// Builds a web-search-enabled response request and prints the returned
/// payload.
pub fn main() -> Result(Nil, OpenAIError) {
  let assert Ok(client) = client.new()

  let input =
    "Search the Hacker News front page and summarize the top 3 stories in one sentence each. And also see if there was any new stories about Apple on Hacker News."
  io.println("\nInput: " <> input)

  let user_location =
    user_location.new()
    |> user_location.with_city("San Francisco")
    |> user_location.with_country("US")

  let web_search_tool =
    web_search.new_web_search()
    |> web_search.user_location(user_location)
    |> web_search.search_context_size(search_context_size.Low)
    |> tool.WebSearchTool

  let request =
    responses.new()
    |> responses.with_model("gpt-5.4")
    |> responses.with_input(response.Text(input))
    |> responses.with_instructions("Ensure to list URL citations")
    |> responses.with_tools([web_search_tool])

  let assert Ok(content) =
    responses.create_with_decoder(client, request, decode_output_message_text())
  io.println("\n" <> content)

  Ok(Nil)
}

fn decode_output_message_text() -> decode.Decoder(String) {
  use outputs <- decode.field("output", decode.list(decode_output_item_text()))
  case first_some(outputs) {
    Some(text) -> decode.success(text)
    None -> decode.failure("", expected: "message output text")
  }
}

fn decode_output_item_text() -> decode.Decoder(Option(String)) {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "message" ->
      decode.at(["content"], decode.at([0], decode.at(["text"], decode.string)))
      |> decode.map(Some)
    _ -> decode.success(None)
  }
}

fn first_some(items: List(Option(a))) -> Option(a) {
  case items {
    [Some(value), ..] -> Some(value)
    [None, ..rest] -> first_some(rest)
    [] -> None
  }
}
