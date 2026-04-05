/// Issues a Responses API call configured to delegate web search to an MCP server.
import gleam/dynamic/decode
import gleam/io
import gleam/option.{type Option, None, Some}
import gleam/string
import openai/client
import openai/error.{type OpenAIError}
import openai/responses
import openai/types/responses/reasoning
import openai/types/responses/response
import openai/types/responses/tool
import openai/types/responses/tools/mcp

/// Builds a GPT-5 Responses request, routes tool calls through the `deepwiki`
/// MCP connector, and prints the returned payload so it can be inspected.
/// Requires `OPENAI_API_KEY` to be set in the environment.
pub fn main() -> Result(Nil, OpenAIError) {
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

  let assert Ok(text) =
    responses.create_with_decoder(client, request, decode_output_message_text())
  io.println("\n" <> text)

  Ok(Nil)
}

fn decode_output_message_text() -> decode.Decoder(String) {
  use outputs <- decode.field("output", decode.list(decode_output_item_text()))
  case first_non_empty_text(option.values(outputs)) {
    Some(text) -> decode.success(text)
    None -> decode.failure("", expected: "non-empty message output text")
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

fn first_non_empty_text(items: List(String)) -> Option(String) {
  case items {
    [text, ..rest] ->
      case string.trim(text) {
        "" -> first_non_empty_text(rest)
        _ -> Some(text)
      }
    [] -> None
  }
}
