/// Issues a Responses API call configured to delegate web search to an MCP server.
import envoy
import gleam/io
import gleam/option.{None, Some}

import openai/error.{type OpenaiError}
import openai/responses
import openai/types/responses/create_response as cr
import openai/types/responses/response.{type Response}
import openai/types/shared

/// Builds a GPT-5 Responses request, routes tool calls through the `deepwiki`
/// MCP connector, and prints the returned payload so it can be inspected.
/// Requires `OPENAI_API_KEY` to be set in the environment.
pub fn main() -> Result(Response, OpenaiError) {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let input =
    "What transport protocols does the 2025-03-26 version of the MCP spec (modelcontextprotocol/modelcontextprotocol) support?"
  io.println("\nPrompt: " <> input)

  let tool =
    cr.Mcp(
      server_label: "deepwiki",
      allowed_tools: None,
      authorization: None,
      connector_id: None,
      headers: None,
      require_approval: Some(cr.McpToolApprovalFilter(
        always: None,
        never: Some(cr.McpToolFilter(
          read_only: None,
          tool_names: Some(["ask_question", "read_wiki_structure"]),
        )),
      )),
      server_description: None,
      server_url: Some("https://mcp.deepwiki.com/mcp"),
    )

  let config =
    responses.default_request()
    |> responses.model(shared.GPT5)
    |> responses.input(cr.InputText(input))
    |> responses.function_tool_choice(cr.Auto)
    |> responses.tools(None, tool)

  // TODO Should it be the users responsibility to tease out the content from the
  // payload?
  let response = responses.create(api_key, config)
  echo response
}
