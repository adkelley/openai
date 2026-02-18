/// Issues a Responses API call configured to use the web search tool.
import envoy
import gleam/io
import gleam/option.{None, Some}

import openai/error.{type OpenaiError}
import openai/responses
import openai/types/responses/create_response as cr
import openai/types/responses/response.{type Response}
import openai/types/shared

/// Builds a web-search-enabled response request and prints the returned payload.
pub fn main() -> Result(Response, OpenaiError) {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let prompt = "Tell me about the International Chopin Piano Competition"
  io.println("\nPrompt: " <> prompt)

  let tool =
    cr.WebSearch(
      filters: Some(
        cr.WebSearchFilters(allowed_domains: Some(["www.wikipedia.org"])),
      ),
      search_context_size: Some(cr.SCSLow),
      user_location: Some(cr.UserLocation(
        city: None,
        country: Some("US"),
        region: None,
        timezone: None,
        type_: Some("approximate"),
      )),
    )

  let config =
    responses.default_request()
    |> responses.model(shared.GPT51)
    |> responses.input(cr.InputText(prompt))
    |> responses.function_tool_choice(cr.Auto)
    |> responses.tools(None, tool)

  // TODO Should it be the users responsibility to tease out the content from the
  // payload?
  let response = responses.create(api_key, config)
  echo response
}
