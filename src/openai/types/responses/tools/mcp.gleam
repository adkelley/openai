import gleam/dict.{type Dict}
import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import openai/types/helpers

pub type McpToolFilter {
  McpToolFilter(read_only: Option(Bool), tool_names: Option(List(String)))
}

fn encode_mcp_tool_filter(mcp_tool_filter: McpToolFilter) -> Json {
  []
  |> helpers.encode_option("read_only", mcp_tool_filter.read_only, json.bool)
  |> helpers.encode_option_list(
    "tool_names",
    mcp_tool_filter.tool_names,
    json.string,
  )
  |> json.object
}

pub fn mcp_tool_filter(
  read_only read_only: Option(Bool),
  tool_names tool_names: Option(List(String)),
) -> McpToolFilter {
  McpToolFilter(read_only:, tool_names:)
}

pub type McpAllowedTools {
  /// A string array of allowed tools
  AllowedTools(List(String))
  /// A filter object to specify which tools are allowed.
  AllowedFilter(McpToolFilter)
}

fn encode_mcp_allowed_tools(mcp_allowed_tools: McpAllowedTools) -> Json {
  case mcp_allowed_tools {
    AllowedTools(tools) -> json.array(tools, json.string)
    AllowedFilter(filter) -> encode_mcp_tool_filter(filter)
  }
}

pub fn with_allowed_tools(mcp: Mcp, allowed_tools: List(String)) -> Mcp {
  Mcp(..mcp, allowed_tools: Some(AllowedTools(allowed_tools)))
}

// TODO decoder needed

pub type McpToolApprovalSetting {
  Always
  Never
}

pub fn with_tool_approval_setting(
  mcp: Mcp,
  setting: McpToolApprovalSetting,
) -> Mcp {
  Mcp(..mcp, require_approval: Some(ApprovalSetting(setting)))
}

fn encode_mcp_tool_approval_setting(
  mcp_tool_approval_setting: McpToolApprovalSetting,
) -> Json {
  case mcp_tool_approval_setting {
    Always -> json.string("always")
    Never -> json.string("never")
  }
}

/// Specify which of the MCP server's tools require
/// approval. Can be always, never, or a filter object
/// associated with tools that require approval.
pub type McpToolApprovalFilter {
  McpToolApprovalFilter(
    /// Tools that should always require approval.
    always: Option(McpToolFilter),
    /// Tools that should never require approval.
    never: Option(McpToolFilter),
  )
}

fn encode_mcp_tool_approval_filter(
  mcp_tool_approval_filter: McpToolApprovalFilter,
) -> Json {
  []
  |> helpers.encode_option(
    "always",
    mcp_tool_approval_filter.always,
    encode_mcp_tool_filter,
  )
  |> helpers.encode_option(
    "never",
    mcp_tool_approval_filter.never,
    encode_mcp_tool_filter,
  )
  |> json.object
}

pub fn with_tool_approval_filter_always(
  config: Mcp,
  always: McpToolFilter,
) -> Mcp {
  Mcp(
    ..config,
    require_approval: Some(
      ApprovalFilter(McpToolApprovalFilter(always: Some(always), never: None)),
    ),
  )
}

pub fn with_tool_approval_filter_never(
  config: Mcp,
  never: McpToolFilter,
) -> Mcp {
  Mcp(
    ..config,
    require_approval: Some(
      ApprovalFilter(McpToolApprovalFilter(never: Some(never), always: None)),
    ),
  )
}

pub type McpToolRequireApproval {
  ApprovalFilter(McpToolApprovalFilter)
  ApprovalSetting(McpToolApprovalSetting)
}

fn encode_mcp_tool_require_approval(
  mcp_tool_require_approval: McpToolRequireApproval,
) -> Json {
  case mcp_tool_require_approval {
    ApprovalFilter(filter) -> encode_mcp_tool_approval_filter(filter)
    ApprovalSetting(setting) -> encode_mcp_tool_approval_setting(setting)
  }
}

// TODO Decoder needed

pub type Mcp {
  Mcp(
    /// A label for this MCP server, used to identify it in tool calls.
    server_label: String,
    /// List of allowed tool names or a filter object.
    allowed_tools: Option(McpAllowedTools),
    /// An OAuth access token that can be used with a remote MCP server, either with a
    /// custom MCP server URL or a service connector. Your application must handle the OAuth
    /// authorization flow and provide the token here.
    authorization: Option(String),
    /// Identifier for service connectors, like those available in ChatGPT.
    /// One of server_url or connector_id must be provided. Learn more about
    /// service connectors here:
    /// https://platform.openai.com/docs/guides/tools-connectors-mcp
    connector_id: Option(String),
    /// Optional HTTP headers to send to the MCP server. Use for authentication or other purposes.
    headers: Option(Dict(String, String)),
    /// Specify which of the MCP server's tools require approval.
    require_approval: Option(McpToolRequireApproval),
    /// Optional description of the MCP server, used to provide more context.
    server_description: Option(String),
    /// The URL for the MCP server. One of server_url or connector_id must be provided.
    server_url: Option(String),
  )
}

pub fn new() -> Mcp {
  Mcp(
    server_label: "",
    allowed_tools: None,
    authorization: None,
    connector_id: None,
    headers: None,
    require_approval: None,
    server_description: None,
    server_url: None,
  )
}

pub fn with_server_label(mcp: Mcp, server_label: String) -> Mcp {
  Mcp(..mcp, server_label:)
}

pub fn encode_mcp(mcp: Mcp) -> Json {
  [
    #("type", json.string("mcp")),
    #("server_label", json.string(mcp.server_label)),
  ]
  |> helpers.encode_option(
    "allowed_tools",
    mcp.allowed_tools,
    encode_mcp_allowed_tools,
  )
  |> helpers.encode_option("authorization", mcp.authorization, json.string)
  |> helpers.encode_option("connector_id", mcp.connector_id, json.string)
  // TODO
  // |> helpers.encode_option("headers", mcp.headers ,
  //   json.dict(_, fn(a) { a }, json.string))
  |> helpers.encode_option(
    "require_approval",
    mcp.require_approval,
    encode_mcp_tool_require_approval,
  )
  |> helpers.encode_option(
    "server_description",
    mcp.server_description,
    json.string,
  )
  |> helpers.encode_option("server_url", mcp.server_url, json.string)
  |> json.object
}

// TODO Why are some of the fields none?
pub fn decode_mcp() -> Decoder(Mcp) {
  use server_label <- decode.field("server_label", decode.string)
  use server_description <- decode.field(
    "server_description",
    decode.optional(decode.string),
  )
  use server_url <- decode.field("server_url", decode.optional(decode.string))
  decode.success(Mcp(
    server_label:,
    allowed_tools: None,
    authorization: None,
    connector_id: None,
    headers: None,
    require_approval: None,
    server_description:,
    server_url:,
  ))
}

pub fn with_server_url(config: Mcp, server_url: String) -> Mcp {
  Mcp(..config, server_url: Some(server_url))
}

pub type Tool {
  Tool(
    /// The JSON Schema for the tool's input.
    input_schema: Json,
    /// The name of the tool.
    name: String,
    /// Tool annotations returned by the MCP server.
    annotations: Option(String),
    /// A human-readable description of the tool.
    description: Option(String),
  )
}

fn encode_tool(tool: Tool) -> Json {
  json.object([
    #("input_schema", tool.input_schema),
    #("name", json.string(tool.name)),
    #("annotations", case tool.annotations {
      Some(annotations) -> json.string(annotations)
      None -> json.null()
    }),
    #("description", case tool.description {
      Some(description) -> json.string(description)
      None -> json.null()
    }),
  ])
}

fn decode_tool() -> Decoder(Tool) {
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.optional(decode.string))
  decode.success(Tool(
    input_schema: json.null(),
    name:,
    annotations: None,
    description:,
  ))
}

pub type McpListTools {
  McpListTools(
    /// The unique ID of the list tools item.
    id: String,
    /// The label of the MCP server that returned the tools.
    server_label: String,
    /// The tools available on the MCP server.
    tools: List(Tool),
    // type: "mcp_list_tools"
    /// The error returned while listing tools, if any.
    error: Option(String),
  )
}

pub fn encode_mcp_list_tools(mcp_list_tools: McpListTools) -> Json {
  json.object([
    #("id", json.string(mcp_list_tools.id)),
    #("server_label", json.string(mcp_list_tools.server_label)),
    #("tools", json.array(mcp_list_tools.tools, encode_tool)),
    #("type", json.string("mcp_list_tools")),
    #("error", case mcp_list_tools.error {
      Some(error) -> json.string(error)
      None -> json.null()
    }),
  ])
}

pub fn decode_mcp_list_tools() -> Decoder(McpListTools) {
  use id <- decode.field("id", decode.string)
  use server_label <- decode.field("server_label", decode.string)
  use tools <- decode.field("tools", decode.list(decode_tool()))
  // use error <- decode.field("error", decode.optional(decode.string))
  decode.success(McpListTools(id:, server_label:, tools:, error: None))
}

pub type McpApprovalRequest {
  McpApprovalRequest(
    /// The unique ID of the approval request.
    id: String,
    /// A JSON string of the arguments for the requested tool invocation.
    arguments: String,
    /// The name of the tool requesting approval.
    name: String,
    /// The label of the MCP server making the request.
    server_label: String,
    // type: "mcp_approval_request"
  )
}

pub fn encode_mcp_approval_request(
  mcp_approval_request: McpApprovalRequest,
) -> Json {
  json.object([
    #("id", json.string(mcp_approval_request.id)),
    #("arguments", json.string(mcp_approval_request.arguments)),
    #("name", json.string(mcp_approval_request.name)),
    #("server_label", json.string(mcp_approval_request.server_label)),
    #("type", json.string("mcp_approval_request")),
  ])
}

pub fn decode_mcp_approval_request() -> Decoder(McpApprovalRequest) {
  use id <- decode.field("id", decode.string)
  use arguments <- decode.field("arguments", decode.string)
  use name <- decode.field("name", decode.string)
  use server_label <- decode.field("server_label", decode.string)
  decode.success(McpApprovalRequest(id:, arguments:, name:, server_label:))
}

pub type McpApprovalResponse {
  McpApprovalResponse(
    /// The ID of the approval request being answered.
    approval_request_id: String,
    /// Whether the approval request is approved.
    approve: Bool,
    // type: "mcp_approval_response"
    /// The unique ID of the approval response item.
    id: Option(String),
    /// The reason for the approval decision.
    reason: Option(String),
  )
}

pub fn encode_mcp_approval_response(
  mcp_approval_response: McpApprovalResponse,
) -> Json {
  json.object([
    #(
      "approval_request_id",
      json.string(mcp_approval_response.approval_request_id),
    ),
    #("approve", json.bool(mcp_approval_response.approve)),
    #("type", json.string("mcp_approval_response")),
    #("id", case mcp_approval_response.id {
      Some(id) -> json.string(id)
      None -> json.null()
    }),
    #("reason", case mcp_approval_response.reason {
      Some(reason) -> json.string(reason)
      None -> json.null()
    }),
  ])
}

pub type McpCall {
  McpCall(
    /// The unique ID of the MCP call.
    id: String,
    /// A JSON string of the arguments passed to the tool.
    arguments: String,
    /// The name of the tool to run.
    name: String,
    /// The label of the MCP server that handled the call.
    server_label: String,
    // type: "mcp_call"
    /// The approval request associated with this call, if one was created.
    approval_request_id: Option(String),
    /// The error returned by the MCP call, if any.
    error: Option(String),
    /// The output returned by the MCP call, if any.
    output: Option(String),
  )
}

pub fn encode_mcp_call(mcp_call: McpCall) -> Json {
  json.object([
    #("id", json.string(mcp_call.id)),
    #("arguments", json.string(mcp_call.arguments)),
    #("name", json.string(mcp_call.name)),
    #("server_label", json.string(mcp_call.server_label)),
    #("type", json.string("mcp_call")),
    #("approval_request_id", case mcp_call.approval_request_id {
      Some(approval_request_id) -> json.string(approval_request_id)
      None -> json.null()
    }),
    #("error", case mcp_call.error {
      Some(error) -> json.string(error)
      None -> json.null()
    }),
    #("output", case mcp_call.output {
      Some(output) -> json.string(output)
      None -> json.null()
    }),
  ])
}

pub fn decode_mcp_call() -> Decoder(McpCall) {
  use id <- decode.field("id", decode.string)
  use arguments <- decode.field("arguments", decode.string)
  use name <- decode.field("name", decode.string)
  use server_label <- decode.field("server_label", decode.string)
  use approval_request_id <- decode.field(
    "approval_request_id",
    decode.optional(decode.string),
  )
  use error <- decode.field("error", decode.optional(decode.string))
  use output <- decode.field("output", decode.optional(decode.string))
  decode.success(McpCall(
    id:,
    arguments:,
    name:,
    server_label:,
    approval_request_id:,
    error:,
    output:,
  ))
}
