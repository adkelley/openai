import gleam/dict.{type Dict}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import openai/responses/types/request.{type Request}
import openai/types as shared

pub fn config_encoder(config: Request) -> Json {
  json.object([
    #("model", shared.model_encoder(config.model)),
    case config.input {
      request.InputText(text) -> #("input", json.string(text))
      request.InputList(input_list) -> #(
        "input",
        json.array(input_list, fn(input_list_item) {
          input_list_item_encoder(input_list_item)
        }),
      )
    },
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
      Some(tool_choice) -> #("tool_choice", tool_choice_encoder(tool_choice))
      None -> #("tool_choice", json.null())
    },
    case config.tools {
      Some(tools) -> #("tools", json.preprocessed_array(tools_encoder(tools)))
      None -> #("tools", json.null())
    },
  ])
}

fn input_list_item_encoder(input_list_item: request.InputListItem) -> Json {
  let input_message_encoder = fn(input_message: request.InputMessage) -> Json {
    let content_item_image_encoder = fn(
      detail: String,
      file_id: Option(String),
      image_url: Option(String),
    ) -> Json {
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

    let content_item_text_encoder = fn(text: String) -> Json {
      json.object([
        #("type", json.string("input_text")),
        #("text", json.string(text)),
      ])
    }

    let content_item_file_encoder = fn(
      file_data: Option(String),
      file_id: Option(String),
      file_url: Option(String),
      filename: Option(String),
    ) -> Json {
      json.object([
        #("type", json.string("input_file")),
        #("file_data", json.nullable(file_data, json.string)),
        #("file_id", json.nullable(file_id, json.string)),
        #("file_url", json.nullable(file_url, json.string)),
        #("filename", json.nullable(filename, json.string)),
      ])
    }

    case input_message {
      request.RoleContent(role:, content:) -> {
        let process_content = fn() -> Json {
          case content {
            request.ContentInputList(xs) -> {
              json.array(xs, fn(x) {
                case x {
                  request.ContentItemFile(
                    file_data:,
                    file_id:,
                    file_url:,
                    filename:,
                  ) ->
                    content_item_file_encoder(
                      file_data,
                      file_id,
                      file_url,
                      filename,
                    )
                  request.ContentItemImage(detail:, file_id:, image_url:) ->
                    content_item_image_encoder(detail, file_id, image_url)
                  request.ContentItemText(text:) ->
                    content_item_text_encoder(text)
                }
              })
            }
            request.ContentInputText(text) -> json.string(text)
          }
        }
        json.object([
          #("role", json.string(role)),
          #("content", process_content()),
        ])
      }
      request.FunctionCallOutput(call_id:, output:) -> {
        json.object([
          #("type", json.string("function_call_output")),
          #("call_id", json.string(call_id)),
          #("output", output),
        ])
      }
    }
  }

  case input_list_item {
    request.InputListItemMessage(item_message) ->
      input_message_encoder(item_message)
    request.InputListItemReference(id:) ->
      json.object([
        #("id", json.string(id)),
        #("type", json.string("item_reference")),
      ])
  }
}

// TODO support all options by replacing "none"
fn tool_choice_encoder(tool_choice: request.FunctionToolChoice) -> Json {
  case tool_choice {
    request.None -> json.null()
    request.Auto -> json.string("auto")
    request.Required -> json.string("required")
    request.AllowedTools(_allowed_tools) -> {
      todo
    }
    request.ForcedFunction(request.FunctionName(name)) -> {
      json.object([
        #("type", json.string("function")),
        #("name", json.string(name)),
      ])
    }
  }
}

fn user_location_encoder(user_location: Option(request.UserLocation)) -> Json {
  case user_location {
    None -> json.null()
    Some(request.UserLocation(city, country, region, timezone, type_)) ->
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

fn search_context_size_encoder(
  search_context_size: Option(request.SearchContextSize),
) -> Json {
  case search_context_size {
    None -> json.null()
    Some(size) ->
      {
        case size {
          request.SCSHigh -> "high"
          request.SCSLow -> "low"
          request.SCSMedium -> "medium"
        }
      }
      |> json.string()
  }
}

fn web_search_filters_encoder(filters: Option(request.WebSearchFilters)) -> Json {
  case filters {
    None -> json.null()
    Some(request.WebSearchFilters(allowed_domains)) ->
      json.object([
        #("allowed_domains", allowed_domains_encoder(allowed_domains)),
      ])
  }
}

fn allowed_domains_encoder(allowed_domains: Option(List(String))) -> Json {
  case allowed_domains {
    None -> json.null()
    Some(xs) -> {
      list.map(xs, fn(x) { json.string(x) })
      |> json.preprocessed_array()
    }
  }
}

fn tools_encoder(tools: List(request.Tools)) -> List(Json) {
  list.map(tools, fn(tool: request.Tools) {
    case tool {
      request.WebSearch(filters:, search_context_size:, user_location:) -> {
        web_search_encoder(filters, search_context_size, user_location)
      }
      request.Mcp(
        server_label:,
        allowed_tools:,
        authorization:,
        connector_id:,
        headers:,
        require_approval:,
        server_description:,
        server_url:,
      ) ->
        mcp_encoder(
          server_label,
          allowed_tools,
          authorization,
          connector_id,
          headers,
          require_approval,
          server_description,
          server_url,
        )
      request.FunctionCalling(name:, description:, parameters:, strict:) ->
        function_calling_encoder(name, description, parameters, strict)
    }
  })
}

fn mcp_encoder(
  server_label: String,
  allowed_tools: Option(request.McpAllowedTools),
  authorization: Option(String),
  connector_id: Option(String),
  headers: Option(Dict(String, String)),
  require_approval: Option(request.McpToolApproval),
  server_description: Option(String),
  server_url: Option(String),
) {
  let allowed_tools_encoder = fn(allowed_tools: Option(request.McpAllowedTools)) {
    #(
      "allowed_tools",
      json.nullable(allowed_tools, fn(a) {
        case a {
          request.McpAllowedTools(tools) -> json.array(tools, json.string)
          request.McpAllowedToolsFilter(filter) -> {
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
  let mcp_tool_filter_encoder = fn(tool_filter: request.McpToolFilter) {
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
  let require_approval_encoder = fn(
    require_approval: Option(request.McpToolApproval),
  ) {
    #(
      "require_approval",
      json.nullable(require_approval, fn(tool_approval) {
        case tool_approval {
          request.McpToolApprovalFilter(always:, never:) -> {
            json.object([
              #("always", json.nullable(always, mcp_tool_filter_encoder)),
              #("never", json.nullable(never, mcp_tool_filter_encoder)),
            ])
          }
          request.McpToolApprovalSetting(setting) -> json.string(setting)
        }
      }),
    )
  }
  let headers_encoder = fn(headers: Option(Dict(String, String))) {
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
    allowed_tools_encoder(allowed_tools),
    #("authorization", json.nullable(authorization, json.string)),
    #("connector_id", json.nullable(connector_id, json.string)),
    headers_encoder(headers),
    require_approval_encoder(require_approval),
    #("server_description", json.nullable(server_description, json.string)),
    #("server_url", json.nullable(server_url, json.string)),
  ])
}

fn function_calling_encoder(
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

fn web_search_encoder(
  filters: Option(request.WebSearchFilters),
  search_context_size: Option(request.SearchContextSize),
  user_location: Option(request.UserLocation),
) -> Json {
  json.object([
    #("type", json.string("web_search")),
    #("filters", web_search_filters_encoder(filters)),
    #("search_context_size", search_context_size_encoder(search_context_size)),
    #("user_location", user_location_encoder(user_location)),
  ])
}
