import gleam/dict.{type Dict}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import openai/types/shared

pub type CreateResponse {
  CreateResponse(
    model: shared.ResponsesModel,
    input: Input,
    instructions: Option(String),
    temperature: Option(Float),
    stream: Option(Bool),
    tool_choice: Option(ToolChoice),
    tools: Option(List(Tools)),
  )
}

pub fn encode_create_response(config: CreateResponse) -> Json {
  json.object([
    #("model", shared.encode_model(config.model)),
    encode_input(config.input),
    case config.instructions {
      None -> #("instructions", json.null())
      Some(instructions) -> #("instructions", json.string(instructions))
    },
    case config.temperature {
      Some(temperature) -> #("temperature", json.float(temperature))
      None -> #("temperature", json.null())
    },
    case config.stream {
      Some(stream) -> #("stream", json.bool(stream))
      None -> #("stream", json.null())
    },
    case config.tool_choice {
      Some(tool_choice) -> #("tool_choice", encode_tool_choice(tool_choice))
      None -> #("tool_choice", json.null())
    },
    case config.tools {
      Some(tools) -> #("tools", json.preprocessed_array(encode_tools(tools)))
      None -> #("tools", json.null())
    },
  ])
}

/// Text, image, or file inputs to the model, used to generate a response.
pub type Input {
  /// A text input to the model, equivalent to a text input with the user role.
  Input(String)
  /// A list of one or many input items to the model, containing different content types.
  ResponseInput(List(ResponseInputItem))
}

fn encode_input(input: Input) {
  case input {
    Input(input) -> #("input", json.string(input))
    ResponseInput(response_input) -> #(
      "input",
      json.array(response_input, fn(response_input_item) {
        encode_response_input_item(response_input_item)
      }),
    )
  }
}

/// A list of one or many input items to the model, containing different content types.
pub type ResponseInputItem {
  EasyInputMessage(
    role: shared.Role,
    content: Content,
    // type: String ; Always "message"
  )
  Message(
    content: Content,
    role: shared.Role,
    status: Option(Status),
    // type: String ; Always "message"
  )
  ResponseOutputMessage(
    id: String,
    content: Content,
    role: shared.Role,
    // Always "assistant"
    status: Status,
    // type: String ; Always "message"
  )
  ResponseReasoningItem(
    /// The unique identifier of the reasoning content.
    id: String,
    /// Reasoning summary content.
    summary: List(SummaryTextContent),
    /// Reasoning text content.
    content: List(ReasoningText),
    /// The status of the item
    status: Option(Status),
  )
  ResponseFunctionToolCall(
    arguments: Json,
    call_id: String,
    id: Option(String),
    status: Option(Status),
    // type: String ; Always "function_call"
  )
}

pub type SummaryTextContent {
  SummaryTextContent(
    text: String,
    // type: String ; Always "summary_text"
  )
}

pub type ReasoningText {
  ReasoningText(
    text: String,
    // type: String ; Always "reasoning_text"
  )
}

fn encode_summary_text_content(text: SummaryTextContent) {
  let SummaryTextContent(text) = text
  json.object([
    #("text", json.string(text)),
    #("type", json.string("summary_text")),
  ])
}

fn encode_reasoning_text(text: ReasoningText) {
  let ReasoningText(text) = text
  json.object([
    #("text", json.string(text)),
    #("type", json.string("reasoning_text")),
  ])
}

fn encode_easy_input_message(item: ResponseInputItem) {
  case item {
    EasyInputMessage(..) as item ->
      json.object([
        #("type", json.string("message")),
        #("role", shared.encode_role(item.role)),
        #("content", encode_content(item.content)),
      ])
    _ -> panic as "wrong encoder for item"
  }
}

fn encode_message(item: ResponseInputItem) {
  case item {
    Message(..) as item -> {
      [
        #("type", json.string("message")),
        #("role", shared.encode_role(item.role)),
        #("content", encode_content(item.content)),
      ]
      |> fn(fields) {
        case item.status {
          Some(status) ->
            list.prepend(fields, #("status", encode_status(status)))
          None -> fields
        }
      }
      |> json.object
    }
    _ -> panic as "wrong encoder for item"
  }
}

fn encode_response_output_message(item: ResponseInputItem) {
  case item {
    ResponseOutputMessage(..) as item ->
      json.object([
        #("id", json.string(item.id)),
        #("type", json.string("message")),
        #("role", shared.encode_role(item.role)),
        #("content", encode_content(item.content)),
        #("status", encode_status(item.status)),
      ])
    _ -> panic as "wrong encoder for item"
  }
}

fn encode_response_reasoning_item(item: ResponseInputItem) {
  case item {
    ResponseReasoningItem(..) as item ->
      [
        #("id", json.string(item.id)),
        #("summary", json.array(item.summary, encode_summary_text_content)),
        #("content", json.array(item.content, encode_reasoning_text)),
        #("type", json.string("reasoning")),
      ]
      |> fn(fields) {
        case item.status {
          Some(status) ->
            list.prepend(fields, #("status", encode_status(status)))
          None -> fields
        }
      }
      |> json.object
    _ -> panic as "wrong encoder for item"
  }
}

fn encode_function_tool_call(item: ResponseInputItem) {
  case item {
    ResponseFunctionToolCall(..) as item ->
      [
        #("arguments", item.arguments),
        #("call_id", json.string(item.call_id)),
      ]
      |> fn(fields) {
        case item.id {
          Some(id) -> list.prepend(fields, #("id", json.string(id)))
          None -> fields
        }
      }
      |> fn(fields) {
        case item.status {
          Some(status) ->
            list.prepend(fields, #("status", encode_status(status)))
          None -> fields
        }
      }
      |> json.object
    _ -> panic as "invalid encoder for item"
  }
}

fn encode_response_input_item(item: ResponseInputItem) {
  case item {
    EasyInputMessage(..) as item -> encode_easy_input_message(item)
    Message(..) as item -> encode_message(item)
    ResponseOutputMessage(..) as item -> encode_response_output_message(item)
    ResponseReasoningItem(..) as item -> encode_response_reasoning_item(item)
    ResponseFunctionToolCall(..) as item -> encode_function_tool_call(item)
  }
}

// pub type InputMessage {
//   /// A message input to the model with a role indicating instruction following hierarchy. Instructions
//   /// given with the developer or system role take precedence over instructions given with the user role.
//   /// Messages with the assistant role are presumed to have been generated by the model in previous interactions.
//   RoleContent(
//     /// The role of the message input. One of user, assistant, system, or
//     /// developer
//     role: String,
//     /// Text, image, or audio input to the model, used to generate a response. i
//     /// Can also contain previous assistant responses.
//     content: Content,
//     // status: Option(InputMessageStatus)
//   )
//   FunctionCallOutput(call_id: String, output: Json)
//   OutputFunctionCall(
//     status: String,
//     id: String,
//     call_id: String,
//     /// The name of the function to call.
//     name: String,
//     /// Function specifec Json to parse within the caller app
//     arguments: String,
//   )
//   OutputReasoning(
//     /// The unique identifier of the reasoning content.
//     id: String,
//     /// Reasoning summary content.
//     summary: List(OutputReasoningSummary),
//     /// Reasoning text content.
//     content: List(OutputReasoningContent),
//   )
//   ShellCallOutput(
//     call_id: String,
//     max_output_length: Int,
//     output: List(ShellExectionOutput),
//   )
//   OutputShellCall(
//     id: String,
//     call_id: String,
//     action: OutputShellCallAction,
//     status: String,
//     environment: Option(String),
//   )
// }

// fn encode_input_message(input_message: InputMessage) -> Json {
//   case input_message {
//     RoleContent(role:, content:) -> encode_role_content(role, content)
//     FunctionCallOutput(call_id:, output:) ->
//       encode_function_call_output(call_id, output)
//     OutputFunctionCall(status:, id:, call_id:, name:, arguments:) ->
//       encode_output_function_call(status, id, call_id, name, arguments)
//     OutputReasoning(id:, summary:, content:) ->
//       encode_output_reasoning(id, summary, content)
//     ShellCallOutput(call_id:, max_output_length:, output:) ->
//       encode_shell_call_output(call_id, max_output_length, output)
//     OutputShellCall(id:, call_id:, action:, status:, environment:) ->
//       encode_output_shell_call(id, call_id, action, status, environment)
//   }
// }

// fn encode_role_content(role: String, content: Content) {
//   json.object([
//     #("role", json.string(role)),
//     #("content", encode_content(content)),
//   ])
// }

fn encode_function_call_output(call_id, output) {
  json.object([
    #("type", json.string("function_call_output")),
    #("call_id", json.string(call_id)),
    #("output", output),
  ])
}

fn encode_output_function_call(
  status: String,
  id: String,
  call_id: String,
  name: String,
  arguments: String,
) {
  json.object([
    #("type", json.string("function_call")),
    #("status", json.string(status)),
    #("id", json.string(id)),
    #("call_id", json.string(call_id)),
    #("name", json.string(name)),
    #("arguments", json.string(arguments)),
  ])
}

fn encode_output_reasoning(
  id: String,
  summary: List(OutputReasoningSummary),
  content: List(OutputReasoningContent),
) {
  json.object([
    #("type", json.string("reasoning")),
    #("id", json.string(id)),
    #(
      "summary",
      json.array(summary, fn(x) {
        case x {
          OutputReasoningSummary(text:) -> json.string(text)
        }
      }),
    ),
    #(
      "content",
      json.array(content, fn(x) {
        case x {
          OutputReasoningContent(text:) -> json.string(text)
        }
      }),
    ),
  ])
}

fn encode_shell_call_output(
  call_id: String,
  max_output_length: Int,
  output: List(ShellExectionOutput),
) {
  json.object([
    #("type", json.string("shell_call_output")),
    #("call_id", json.string(call_id)),
    #("max_output_length", json.int(max_output_length)),
    #(
      "output",
      json.array(output, fn(x) {
        let encode_outcome = fn(outcome: ShellExectionOutcome) {
          case outcome {
            ShellExecutionOutcome(type_:, exit_code:) -> {
              json.object([
                #("type", json.string(type_)),
                #("exit_code", json.int(exit_code)),
              ])
            }
          }
        }
        case x {
          ShellExectionOutput(stdout:, stderr:, outcome:) -> {
            json.object([
              #("stdout", json.string(stdout)),
              #("stderr", json.string(stderr)),
              #("outcome", encode_outcome(outcome)),
            ])
          }
        }
      }),
    ),
  ])
}

fn encode_output_shell_call(id, call_id, action, status, environment) {
  let encode_action = fn() {
    case action {
      OutputShellCallAction(commands:, timeout_ms:, max_output_length:) -> {
        json.object([
          #("commands", json.array(commands, json.string)),
          #("timeout_ms", json.int(timeout_ms)),
          #("max_output_length", json.int(max_output_length)),
        ])
      }
    }
  }
  json.object([
    #("type", json.string("shell_call")),
    #("id", json.string(id)),
    #("call_id", json.string(call_id)),
    #("action", encode_action()),
    #("status", json.string(status)),
    #("environment", case environment {
      Some(text) -> json.string(text)
      None -> json.null()
    }),
  ])
}

pub type OutputShellCallAction {
  OutputShellCallAction(
    commands: List(String),
    timeout_ms: Int,
    max_output_length: Int,
  )
}

pub type ShellExectionOutput {
  ShellExectionOutput(
    stdout: String,
    stderr: String,
    outcome: ShellExectionOutcome,
  )
}

pub type ShellExectionOutcome {
  ShellExecutionOutcome(type_: String, exit_code: Int)
}

/// Reasoning text content.
/// 
pub type OutputReasoningSummary {
  OutputReasoningSummary(text: String)
}

pub type OutputReasoningContent {
  OutputReasoningContent(text: String)
}

pub type Content {
  // pub type ContentInput {
  /// A text input to the model.
  ContentText(String)
  /// A list of one or many input items to the model, containing different content types.
  ResponseInputMessageContentList(List(ContentItem))
}

fn encode_content(content: Content) {
  case content {
    ResponseInputMessageContentList(xs) -> {
      json.array(xs, fn(x) { encode_content_item(x) })
    }
    ContentText(text) -> json.string(text)
  }
}

/// A list of one or many input items to the model, containing different content types.
pub type ContentItem {
  /// The text input to the model.
  ContentItemText(text: String)
  /// An image input to the model. Learn about image inputs.
  ContentItemImage(
    /// The detail level of the image to be sent to the model. One of high, low, or auto.
    /// Defaults to auto.
    detail: String,
    /// The ID of the file to be sent to the model.
    file_id: Option(String),
    /// The URL of the image to be sent to the model. A fully qualified URL or base64 encoded
    /// image in a data URL.
    image_url: Option(String),
  )
  /// A file input to the model.
  ContentItemFile(
    /// The content of the file to be sent to the model.
    file_data: Option(String),
    /// The ID of the file to be sent to the model.
    file_id: Option(String),
    /// The URL of the file to be sent to the model.
    file_url: Option(String),
    /// The name of the file to be sent to the model.
    filename: Option(String),
  )
}

fn encode_content_item(content_item: ContentItem) {
  case content_item {
    ContentItemText(text:) -> {
      json.object([
        #("type", json.string("input_text")),
        #("text", json.string(text)),
      ])
    }
    ContentItemImage(detail:, file_id:, image_url:) -> {
      json.object([
        #("type", json.string("input_image")),
        #("detail", json.string(detail)),
        case file_id {
          None -> {
            let assert Some(image_url) = image_url
            #("image_url", json.string(image_url))
          }
          Some(file_id) -> #("file_id", json.string(file_id))
        },
      ])
    }
    ContentItemFile(file_data:, file_id:, file_url:, filename:) -> {
      json.object([
        #("type", json.string("input_file")),
        #("file_data", json.nullable(file_data, json.string)),
        #("file_id", json.nullable(file_id, json.string)),
        #("file_url", json.nullable(file_url, json.string)),
        #("filename", json.nullable(filename, json.string)),
      ])
    }
  }
}

/// The status of item. One of in_progress, completed, or incomplete. Populated when items are
/// returned via API.
pub type Status {
  InProgress
  Completed
  Incomplete
}

fn encode_status(status: Status) {
  case status {
    InProgress -> "in_progress"
    Completed -> "completed"
    Incomplete -> "incomplete"
  }
  |> json.string()
}

/// When generating model responses, you can extend capabilities using built‑in
/// tools and remote MCP servers. These enable the model to search the web,
/// retrieve from your files, call your own functions, or access third‑party
/// services.
pub type Tools {
  WebSearch(
    /// Filters for the search.
    filters: Option(WebSearchFilters),
    /// High level guidance for the amount of context window space to use for the search.
    /// One of low, medium, or high. medium is the default.
    search_context_size: Option(SearchContextSize),
    user_location: Option(UserLocation),
  )
  Mcp(
    /// A label for this MCP server, used to identify it in tool calls.
    server_label: String,
    /// List of allowed tool names or a filter object.
    allowed_tools: Option(McpAllowedTools),
    /// An OAuth access token that can be used with a remote MCP server, either with a
    /// custom MCP server URL or a service connector. Your application must handle the OAuth
    /// authorization flow and provide the token here.
    authorization: Option(String),
    // TODO: Added supported connectors (https://platform.openai.com/docs/guides/tools-connectors-mcp)
    /// Identifier for service connectors, like those available in ChatGPT. One of server_url or
    /// connector_id must be provided. Learn more about service connectors here:
    /// https://platform.openai.com/docs/guides/tools-connectors-mcp
    connector_id: Option(String),
    /// Optional HTTP headers to send to the MCP server. Use for authentication or other purposes.
    headers: Option(Dict(String, String)),
    /// Specify which of the MCP server's tools require approval.
    require_approval: Option(McpToolApproval),
    /// Optional description of the MCP server, used to provide more context.
    server_description: Option(String),
    /// The URL for the MCP server. One of server_url or connector_id must be provided.
    server_url: Option(String),
  )
  FunctionTool(
    /// The function's name (e.g. get_weather)
    name: String,
    /// Details on when and how to use the function
    description: String,
    /// JSON schema defining the function's input arguments
    parameters: Json,
    /// Whether to enforce strict mode for the function call
    strict: Bool,
  )
  ShellCall
}

fn encode_tools(tools: List(Tools)) -> List(Json) {
  list.map(tools, fn(tool: Tools) {
    case tool {
      WebSearch(filters:, search_context_size:, user_location:) -> {
        encode_web_search(filters, search_context_size, user_location)
      }
      Mcp(
        server_label:,
        allowed_tools:,
        authorization:,
        connector_id:,
        headers:,
        require_approval:,
        server_description:,
        server_url:,
      ) ->
        encode_mcp(
          server_label,
          allowed_tools,
          authorization,
          connector_id,
          headers,
          require_approval,
          server_description,
          server_url,
        )
      FunctionTool(name:, description:, parameters:, strict:) ->
        encode_function_calling(name, description, parameters, strict)
      ShellCall -> {
        json.object([#("type", json.string("shell"))])
      }
    }
  })
}

fn encode_function_calling(
  name: String,
  description: String,
  parameters: Json,
  strict: Bool,
) {
  json.object([
    #("type", json.string("function")),
    #("name", json.string(name)),
    #("description", json.string(description)),
    #("strict", json.bool(strict)),
    #("parameters", parameters),
  ])
}

fn encode_web_search(
  filters: Option(WebSearchFilters),
  search_context_size: Option(SearchContextSize),
  user_location: Option(UserLocation),
) -> Json {
  json.object([
    #("type", json.string("web_search")),
    #("filters", encode_web_search_filters(filters)),
    #("search_context_size", encode_search_context_size(search_context_size)),
    #("user_location", encode_user_location(user_location)),
  ])
}

fn encode_search_context_size(
  search_context_size: Option(SearchContextSize),
) -> Json {
  case search_context_size {
    None -> json.null()
    Some(size) ->
      {
        case size {
          SCSHigh -> "high"
          SCSLow -> "low"
          SCSMedium -> "medium"
        }
      }
      |> json.string()
  }
}

fn encode_web_search_filters(filters: Option(WebSearchFilters)) -> Json {
  case filters {
    None -> json.null()
    Some(WebSearchFilters(allowed_domains)) ->
      json.object([
        #("allowed_domains", encode_allowed_domains(allowed_domains)),
      ])
  }
}

fn encode_allowed_domains(allowed_domains: Option(List(String))) -> Json {
  case allowed_domains {
    None -> json.null()
    Some(xs) -> {
      list.map(xs, fn(x) { json.string(x) })
      |> json.preprocessed_array()
    }
  }
}

fn encode_user_location(user_location: Option(UserLocation)) -> Json {
  case user_location {
    None -> json.null()
    Some(UserLocation(city, country, region, timezone, type_)) ->
      json.object([
        case type_ {
          None -> #("type", json.null())
          Some(_) -> #("type", json.string("approximate"))
        },
        case city {
          None -> #("city", json.null())
          Some(x) -> #("city", json.string(x))
        },
        case country {
          None -> #("country", json.null())
          Some(x) -> #("country", json.string(x))
        },
        case region {
          None -> #("region", json.null())
          Some(x) -> #("region", json.string(x))
        },
        case timezone {
          None -> #("timezone", json.null())
          Some(x) -> #("timezone", json.string(x))
        },
      ])
  }
}

fn encode_mcp(
  server_label: String,
  allowed_tools: Option(McpAllowedTools),
  authorization: Option(String),
  connector_id: Option(String),
  headers: Option(Dict(String, String)),
  require_approval: Option(McpToolApproval),
  server_description: Option(String),
  server_url: Option(String),
) {
  let encode_headers = fn(headers: Option(Dict(String, String))) {
    #(
      "headers",
      json.nullable(headers, fn(header) {
        json.dict(header, fn(a) { a }, json.string)
      }),
    )
  }

  json.object([
    #("type", json.string("mcp")),
    #("server_label", json.string(server_label)),
    encode_mcp_allowed_tools(allowed_tools),
    #("authorization", json.nullable(authorization, json.string)),
    #("connector_id", json.nullable(connector_id, json.string)),
    encode_headers(headers),
    encode_mcp_tool_approval(require_approval),
    #("server_description", json.nullable(server_description, json.string)),
    #("server_url", json.nullable(server_url, json.string)),
  ])
}

pub type McpToolApproval {
  /// Specify which of the MCP server's tools require approval. Can be always, never, or a filter
  /// object associated with tools that require approval.
  McpToolApprovalFilter(
    /// A filter object to specify which tools are allowed.
    always: Option(McpToolFilter),
    /// A filter object to specify which tools are allowed.
    never: Option(McpToolFilter),
  )
  /// Specify a single approval policy for all tools. One of always or never. When set to always,
  /// all tools will require approval. When set to never, all tools will not require approval.
  McpToolApprovalSetting(String)
}

fn encode_mcp_tool_approval(require_approval: Option(McpToolApproval)) {
  #(
    "require_approval",
    json.nullable(require_approval, fn(tool_approval) {
      case tool_approval {
        McpToolApprovalFilter(always:, never:) -> {
          json.object([
            #("always", json.nullable(always, encode_mcp_tool_filter)),
            #("never", json.nullable(never, encode_mcp_tool_filter)),
          ])
        }
        McpToolApprovalSetting(setting) -> json.string(setting)
      }
    }),
  )
}

pub type McpAllowedTools {
  /// A string array of allowed tools
  McpAllowedTools(List(String))
  /// A filter object to specify which tools are allowed.
  McpAllowedToolsFilter(McpToolFilter)
}

fn encode_mcp_allowed_tools(allowed_tools: Option(McpAllowedTools)) {
  #(
    "allowed_tools",
    json.nullable(allowed_tools, fn(a) {
      case a {
        McpAllowedTools(tools) -> json.array(tools, json.string)
        McpAllowedToolsFilter(filter) -> {
          json.object([
            #("read_only", json.nullable(filter.read_only, json.bool)),
            #(
              "tool_names",
              json.nullable(filter.tool_names, fn(tool) {
                json.array(tool, json.string)
              }),
            ),
          ])
        }
      }
    }),
  )
}

pub type McpToolFilter {
  McpToolFilter(
    /// Indicates whether or not a tool modifies data or is read-only. If an MCP server
    /// is annotated with readOnlyHint, it will match this filter.
    read_only: Option(Bool),
    /// List of allowed tool names.
    tool_names: Option(List(String)),
  )
}

fn encode_mcp_tool_filter(tool_filter: McpToolFilter) {
  json.object([
    #("read_only", json.nullable(tool_filter.read_only, json.bool)),
    #(
      "tool_names",
      json.nullable(tool_filter.tool_names, fn(tool_names) {
        json.array(tool_names, json.string)
      }),
    ),
  ])
}

pub type WebSearchFilters {
  WebSearchFilters(allowed_domains: Option(List(String)))
}

pub type SearchContextSize {
  SCSLow
  SCSMedium
  SCSHigh
}

pub type UserLocation {
  UserLocation(
    /// Free text input for the city of the user, e.g. San Francisco.
    city: Option(String),
    /// The two-letter ISO country code of the user, e.g. US.
    country: Option(String),
    /// Free text input for the region of the user, e.g. California.
    region: Option(String),
    /// The IANA timezone of the user, e.g. America/Los_Angeles.
    timezone: Option(String),
    /// The type of location approximation. Always approximate.
    type_: Option(String),
  )
}

pub type BuiltInTools {
  FileSearch
  WebSearchPreview
  ComputerUsePreview
  CodeInterpreter
  ImageGeneration
}

fn encode_built_in_tools(built_in_tools: BuiltInTools) {
  let tool_string = case built_in_tools {
    FileSearch -> "file_search"
    WebSearchPreview -> "web_search_preview"
    ComputerUsePreview -> "computer_use_preview"
    CodeInterpreter -> "code_interpreter"
    ImageGeneration -> "image_generation"
  }
  json.object([#("type", json.string(tool_string))])
}

pub type ToolChoice {
  ToolChoiceOptions(Mode)
  ToolChoiceAllowed(
    mode: Mode,
    tools: Json,
    // type: String, ; Always "allowed_tools"
  )
  ToolChoiceTypes(BuiltInTools)
  ToolChoiceFunction(
    name: String,
    // type: String, ; Always "function"
  )
}

pub type Mode {
  Auto
  Required
  Nothing
}

fn encode_mode(mode: Mode) {
  case mode {
    Auto -> json.string("auto")
    Required -> json.string("required")
    // None is a reserved type, so we use Nothing
    Nothing -> json.string("none")
  }
}

fn encode_tool_choice(tool_choice: ToolChoice) {
  case tool_choice {
    ToolChoiceOptions(mode) -> encode_mode(mode)
    ToolChoiceAllowed(mode:, tools:) ->
      json.object([
        #("mode", encode_mode(mode)),
        #("tools", tools),
        #("type", json.string("allowed_tools")),
      ])
    ToolChoiceTypes(built_in_tools) -> encode_built_in_tools(built_in_tools)
    ToolChoiceFunction(name:) ->
      json.object([
        #("name", json.string(name)),
        #("type", json.string("function")),
      ])
  }
}
