import envoy
import gleam/io
import gleam/option.{None, Some}

import openai/error.{type OpenaiError}
import openai/responses
import openai/responses/types/request.{Auto, Low, WebSearch, WebSearchFilters}
import openai/responses/types/response.{type Response}
import openai/shared/types as shared

pub fn main() -> Result(Response, OpenaiError) {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let prompt = "Tell me about the International Chopin Piano Competition"
  io.println("\nPrompt: " <> prompt)

  let tool =
    WebSearch(
      filters: Some(
        WebSearchFilters(allowed_domains: Some(["www.wikipedia.org"])),
      ),
      search_context_size: Some(Low),
      user_location: Some(request.UserLocation(
        city: None,
        country: Some("US"),
        region: None,
        timezone: None,
        type_: Some("approximate"),
      )),
    )

  let config =
    responses.default_request()
    |> responses.model(shared.GPT41)
    |> responses.input(prompt)
    |> responses.tool_choice(Auto)
    |> responses.tools(None, tool)

  // TODO Should it be the users responsibility to tease out the content from the
  // payload?
  let response = responses.create(api_key, config)
  echo response
}
