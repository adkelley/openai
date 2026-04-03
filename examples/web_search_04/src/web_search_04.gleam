/// Issues a Responses API call configured to use the web search tool.
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import openai/client
import openai/error.{type OpenAIError}
import openai/responses
import openai/types/responses/message
import openai/types/responses/response
import openai/types/responses/tool
import openai/types/responses/tools/search_context_size
import openai/types/responses/tools/user_location
import openai/types/responses/tools/web_search

/// Builds a web-search-enabled response request and prints the returned
/// payload.
pub fn main() -> Result(response.Response, OpenAIError) {
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
    |> responses.with_model("gpt-5.1")
    |> responses.with_input(response.Text(input))
    |> responses.with_instructions("Ensure to list URL citations")
    |> responses.with_tools([web_search_tool])

  let assert Ok(response) = responses.create(client, request)
  // TODO find_output_message?
  let assert Some(message.ResponseOutputMessage(content:, ..)) =
    find_output_message(response.output)

  // Print the response and citations
  let assert Ok(message.OutputTextItem(message.OutputText(text:, ..))) =
    list.first(content)
  io.println("\n" <> text)

  Ok(response)
}

fn find_output_message(
  output: List(response.InputOutput),
) -> Option(message.ResponseOutputMessage) {
  case output {
    [response.ResponseOutputMessageItem(response_output_message), ..] ->
      Some(response_output_message)
    [_, ..rest] -> find_output_message(rest)
    [] -> None
  }
}
