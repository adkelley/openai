import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option}
import openai/types/helpers

pub type Param {
  /// Constrains the tools available to the model to a pre-defined set.
  Allowed(ToolChoiceAllowed)
  /// Use this option to force the model to call a specific function.
  Function(ToolChoiceFunction)
  /// Use this option to force the model to call a specific tool on a remote
  /// MCP server.
  Mcp(ToolChoiceMcp)
  /// Use this option to force the model to call a specific custom tool.
  Custom(ToolChoiceCustom)
  /// Forces the model to call the apply_patch tool when executing a tool call.
  ApplyPatch
  // type: "apply_patch"
  Shell
  // type: "shell"
  Types(ToolChoiceTypes)
  Options(ToolChoiceOptions)
}

pub fn encode_param(tool_choice_param: Param) -> Json {
  case tool_choice_param {
    Allowed(allowed) -> encode_tool_choice_allowed(allowed)
    Function(function) -> encode_tool_choice_function(function)
    Mcp(mcp) -> encode_tool_choice_mcp(mcp)
    Custom(custom) -> encode_tool_choice_custom(custom)
    ApplyPatch -> json.object([#("type", json.string("apply_patch"))])
    Shell -> json.object([#("type", json.string("shell"))])
    Types(tool_choice_types) -> encode_tool_choice_types(tool_choice_types)
    Options(tool_choice_options) ->
      encode_tool_choice_options(tool_choice_options)
  }
}

pub fn decode_tool_choice_param() -> Decoder(Param) {
  decode.one_of(decode_tool_choice_options() |> decode.map(Options), or: [
    decode_tool_choice_allowed() |> decode.map(Allowed),
    decode_tool_choice_function() |> decode.map(Function),
    decode_tool_choice_mcp() |> decode.map(Mcp),
    decode_tool_choice_custom() |> decode.map(Custom),
    decode_tool_choice_types() |> decode.map(Types),
    decode.field("type", decode.string, fn(type_) {
      decode.success(case type_ {
        "apply_patch" -> ApplyPatch
        "shell" -> Shell
        _ -> panic as type_
      })
    }),
  ])
}

/// Constrains the tools available to the model to a pre-defined set.
pub type ToolChoiceAllowed {
  ToolChoiceAllowed(
    /// Whether the model may choose among the allowed tools automatically or must call one.
    mode: ToolChoiceMode,
    /// A list of tool definitions that the model should be allowed to call.
    tools: List(Json),
    // Allowed tool configuration type. Always allowed_tools.
    // type: "allowed_tools"
  )
}

fn encode_tool_choice_allowed(tool_choice_allowed: ToolChoiceAllowed) -> Json {
  json.object([
    #("mode", encode_tool_choice_mode(tool_choice_allowed.mode)),
    #("tools", json.array(tool_choice_allowed.tools, fn(tool) { tool })),
    #("type", json.string("allowed_tools")),
  ])
}

fn decode_tool_choice_allowed() -> Decoder(ToolChoiceAllowed) {
  use mode <- decode.field("mode", decode_tool_choice_mode())
  use _tools <- decode.field("tools", decode.list(decode.dynamic))
  decode.success(ToolChoiceAllowed(mode:, tools: []))
}

/// auto allows the model to pick from among the allowed tools and generate a
/// message.
///
/// required requires the model to call one or more of the allowed tools.
pub type ToolChoiceMode {
  ToolChoiceModeAuto
  ToolChoiceModeRequired
}

fn encode_tool_choice_mode(tool_choice_mode: ToolChoiceMode) -> Json {
  case tool_choice_mode {
    ToolChoiceModeAuto -> "auto"
    ToolChoiceModeRequired -> "required"
  }
  |> json.string
}

fn decode_tool_choice_mode() -> Decoder(ToolChoiceMode) {
  decode.string
  |> decode.map(fn(mode) {
    case mode {
      "auto" -> ToolChoiceModeAuto
      "required" -> ToolChoiceModeRequired
      _ -> panic as mode
    }
  })
}

pub type ToolChoiceFunction {
  ToolChoiceFunction(
    /// The name of the function to call.
    name: String,
    // For function calling, the type is always function.
    // type: "function"
  )
}

fn encode_tool_choice_function(tool_choice_function: ToolChoiceFunction) -> Json {
  json.object([
    #("name", json.string(tool_choice_function.name)),
    #("type", json.string("function")),
  ])
}

fn decode_tool_choice_function() -> Decoder(ToolChoiceFunction) {
  use name <- decode.field("name", decode.string)
  decode.success(ToolChoiceFunction(name:))
}

pub type ToolChoiceMcp {
  ToolChoiceMcp(
    /// The label of the MCP server to call.
    server_label: String,
    // type: "mcp"
    /// The name of the tool to call on the server.
    name: Option(String),
  )
}

fn encode_tool_choice_mcp(tool_choice_mcp: ToolChoiceMcp) -> Json {
  [
    #("server_label", json.string(tool_choice_mcp.server_label)),
    #("type", json.string("mcp")),
  ]
  |> helpers.encode_option("name", tool_choice_mcp.name, json.string)
  |> json.object
}

fn decode_tool_choice_mcp() -> Decoder(ToolChoiceMcp) {
  use server_label <- decode.field("server_label", decode.string)
  use name <- decode.field("name", decode.optional(decode.string))
  decode.success(ToolChoiceMcp(server_label:, name:))
}

pub type ToolChoiceCustom {
  ToolChoiceCustom(
    /// The name of the custom tool to call.
    name: String,
    // type: "custom"
  )
}

fn encode_tool_choice_custom(tool_choice_custom: ToolChoiceCustom) -> Json {
  json.object([
    #("name", json.string(tool_choice_custom.name)),
    #("type", json.string("custom")),
  ])
}

fn decode_tool_choice_custom() -> Decoder(ToolChoiceCustom) {
  use name <- decode.field("name", decode.string)
  decode.success(ToolChoiceCustom(name:))
}

pub type ToolChoiceTypes {
  FileSearch
  WebSearchPreview
  ComputerUsePreview
  CodeInterpreter
  ImageGeneration
}

fn encode_tool_choice_types(tool_choice_types: ToolChoiceTypes) -> Json {
  let tool = case tool_choice_types {
    FileSearch -> "file_search"
    WebSearchPreview -> "web_search_preview"
    ComputerUsePreview -> "computer_use_preview"
    CodeInterpreter -> "code_interpreter"
    ImageGeneration -> "image_generation"
  }

  json.object([#("type", json.string(tool))])
}

fn decode_tool_choice_types() -> Decoder(ToolChoiceTypes) {
  use type_ <- decode.field("type", decode.string)
  decode.success(case type_ {
    "file_search" -> FileSearch
    "web_search_preview" -> WebSearchPreview
    "computer_use_preview" -> ComputerUsePreview
    "code_interpreter" -> CodeInterpreter
    "image_generation" -> ImageGeneration
    _ -> panic as type_
  })
}

pub type ToolChoiceOptions {
  Required
  None
  Auto
}

fn encode_tool_choice_options(tool_choice_options: ToolChoiceOptions) -> Json {
  case tool_choice_options {
    Required -> json.string("required")
    None -> json.string("none")
    Auto -> json.string("auto")
  }
}

fn describe_tool_choice_options(option: String) -> ToolChoiceOptions {
  case option {
    "required" -> Required
    "none" -> None
    "auto" -> Auto
    _ -> panic as option
  }
}

fn decode_tool_choice_options() -> Decoder(ToolChoiceOptions) {
  decode.string
  |> decode.map(fn(option) { describe_tool_choice_options(option) })
}

pub fn options(option: String) {
  Options(describe_tool_choice_options(option))
}
