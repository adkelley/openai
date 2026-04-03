/// Issues a Responses API call configured to delegate web search to an MCP server.
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import openai/client
import openai/error.{type OpenAIError}
import openai/responses
import openai/types/responses/message
import openai/types/responses/reasoning
import openai/types/responses/response
import openai/types/responses/tool
import openai/types/responses/tools/mcp

/// Builds a GPT-5 Responses request, routes tool calls through the `deepwiki`
/// MCP connector, and prints the returned payload so it can be inspected.
/// Requires `OPENAI_API_KEY` to be set in the environment.
pub fn main() -> Result(response.Response, OpenAIError) {
  let assert Ok(client) = client.new()

  let input =
    "What transport protocols does the 2025-03-26 version of the MCP spec (modelcontextprotocol/modelcontextprotocol) support?"
  io.println("\nPrompt: " <> input)

  let tool_filter =
    mcp.mcp_tool_filter(
      read_only: None,
      tool_names: Some(["ask_question", "read_wiki_structure"]),
    )
  let mcp_tool =
    mcp.new()
    |> mcp.with_server_label("deepwiki")
    |> mcp.with_allowed_tools(["ask_question", "read_wiki_structure"])
    |> mcp.with_tool_approval_filter_never(tool_filter)
    |> mcp.with_server_url("https://mcp.deepwiki.com/mcp")
    |> tool.McpTool

  let reasoning =
    reasoning.ReasoningDef(
      effort: Some(reasoning.Medium),
      summary: Some(reasoning.Detailed),
    )

  let request =
    responses.new()
    |> responses.with_model("gpt-5-mini")
    |> responses.with_input(response.Text(input))
    |> responses.with_tools([mcp_tool])
    |> responses.with_reasoning(reasoning)

  let assert Ok(response) = responses.create(client, request)

  // TODO Should this be a utility function?
  // Extract the output message
  let assert Ok(response.ResponseOutputMessageItem(message.ResponseOutputMessage(
    content:,
    ..,
  ))) = list.last(response.output)
  let assert Ok(message.OutputTextItem(message.OutputText(text:, ..))) =
    list.first(content)
  io.println("\n" <> text)

  Ok(response)
}
