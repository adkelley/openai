import gleam/dynamic/decode.{type Decoder}
import gleam/option
import openai/responses/types/response.{type Response, Response}

pub fn usage_decoder() {
  let input_tokens_details_decoder = fn() {
    use cached_tokens <- decode.field("cached_tokens", decode.int)
    decode.success(response.InputTokensDetails(cached_tokens:))
  }
  let output_tokens_details_decoder = fn() {
    use reasoning_tokens <- decode.field("reasoning_tokens", decode.int)
    decode.success(response.OutputTokensDetails(reasoning_tokens:))
  }
  use input_tokens <- decode.field("input_tokens", decode.int)
  use input_tokens_details <- decode.field(
    "input_tokens_details",
    input_tokens_details_decoder(),
  )
  use output_tokens <- decode.field("output_tokens", decode.int)
  use output_tokens_details <- decode.field(
    "output_tokens_details",
    output_tokens_details_decoder(),
  )
  use total_tokens <- decode.field("total_tokens", decode.int)
  decode.success(response.Usage(
    input_tokens:,
    input_tokens_details:,
    output_tokens:,
    output_tokens_details:,
    total_tokens:,
  ))
}

fn user_location_decoder() -> Decoder(response.UserLocation) {
  use city <- decode.field("city", decode.optional(decode.string))
  use country <- decode.field("country", decode.optional(decode.string))
  use region <- decode.field("region", decode.optional(decode.string))
  use timezone <- decode.field("timezone", decode.optional(decode.string))
  use type_ <- decode.field("type", decode.optional(decode.string))
  decode.success(response.UserLocation(
    city:,
    country:,
    region:,
    timezone:,
    type_:,
  ))
}

fn filters_decoder() -> Decoder(response.Filters) {
  use allowed_domains <- decode.field(
    "allowed_domains",
    decode.optional(decode.list(decode.string)),
  )
  decode.success(response.Filters(allowed_domains:))
}

fn web_search_decoder() -> Decoder(response.Tool) {
  use search_context_size <- decode.field(
    "search_context_size",
    decode.optional(decode.string),
  )
  use filters <- decode.field("filters", decode.optional(filters_decoder()))
  use user_location <- decode.field(
    "user_location",
    decode.optional(user_location_decoder()),
  )
  decode.success(response.WebSearch(
    search_context_size:,
    filters:,
    user_location:,
  ))
}

fn mcp_decoder() -> Decoder(response.Tool) {
  let require_approval_decoder = fn() {
    let always_decoder = fn() {
      use read_only <- decode.field("read_only", decode.optional(decode.bool))
      use tool_names <- decode.field("tool_names", decode.list(decode.string))
      decode.success(response.Always(read_only:, tool_names:))
    }
    let never_decoder = fn() {
      use read_only <- decode.field("read_only", decode.optional(decode.bool))
      use tool_names <- decode.field("tool_names", decode.list(decode.string))
      decode.success(response.Never(read_only:, tool_names:))
    }
    use always <- decode.field("always", decode.optional(always_decoder()))
    use never <- decode.field("never", decode.optional(never_decoder()))
    decode.success(response.ToolMcpRequireApproval(always:, never:))
  }
  use allowed_tools <- decode.field(
    "allowed_tools",
    decode.optional(decode.list(decode.string)),
  )

  use require_approval <- decode.field(
    "require_approval",
    require_approval_decoder(),
  )
  use server_description <- decode.field(
    "server_description",
    decode.optional(decode.string),
  )
  use server_url <- decode.field("server_url", decode.string)
  use server_label <- decode.field("server_label", decode.string)
  decode.success(response.Mcp(
    allowed_tools:,
    require_approval:,
    server_description:,
    server_url:,
    server_label:,
  ))
}

fn ranking_options_decoder() -> Decoder(response.RankingOptions) {
  use ranker <- decode.field("ranker", decode.string)
  use score_threshold <- decode.field("score_threshold", decode.float)
  decode.success(response.RankingOptions(ranker:, score_threshold:))
}

fn value_decoder() -> Decoder(response.Value) {
  let value_string_decoder = fn() {
    use value_string <- decode.field("value", decode.string)
    decode.success(response.ValueString(value_string))
  }
  let value_float_decoder = fn() {
    use value_float <- decode.field("value", decode.float)
    decode.success(response.ValueFloat(value_float))
  }
  let value_bool_decoder = fn() {
    use value_bool <- decode.field("value", decode.bool)
    decode.success(response.ValueBool(value_bool))
  }
  let value_array_string_decoder = fn() {
    use value_array <- decode.field("value", decode.list(decode.string))
    decode.success(response.ValueArrayString(value_array))
  }
  let value_array_float_decoder = fn() {
    use value_array_float <- decode.field("value", decode.list(decode.float))
    decode.success(response.ValueArrayFloat(value_array_float))
  }
  let value_array_bool_decoder = fn() {
    use value_array_bool <- decode.field("value", decode.list(decode.bool))
    decode.success(response.ValueArrayBool(value_array_bool))
  }

  decode.one_of(value_string_decoder(), [
    value_float_decoder(),
    value_bool_decoder(),
    value_array_string_decoder(),
    value_array_float_decoder(),
    value_array_bool_decoder(),
  ])
}

fn file_search_filter_decoder() -> Decoder(response.FileSearchFilters) {
  decode.one_of(comparison_filter_decoder(), [])
}

fn comparison_filter_decoder() -> Decoder(response.FileSearchFilters) {
  use key <- decode.field("key", decode.string)
  use type_ <- decode.field("type", decode.string)
  use value <- decode.field("value", value_decoder())
  decode.success(response.ComparisonFilter(key:, type_:, value:))
}

fn tool_decoder() -> Decoder(response.Tool) {
  decode.one_of(function_decoder(), or: [
    file_search_decoder(),
    computer_use_decoder(),
    web_search_decoder(),
    mcp_decoder(),
  ])
}

fn function_decoder() -> Decoder(response.Tool) {
  use name <- decode.field("name", decode.string)
  use description <- decode.field("description", decode.string)
  use strict <- decode.field("strict", decode.bool)
  use parameters <- decode.field("parameters", decode.dynamic)
  decode.success(response.Function(name:, description:, parameters:, strict:))
}

fn computer_use_decoder() -> Decoder(response.Tool) {
  use display_height <- decode.field("display_height", decode.int)
  use display_width <- decode.field("display_width", decode.int)
  use environment <- decode.field("environment", decode.string)
  decode.success(response.ComputerUse(
    display_height:,
    display_width:,
    environment:,
  ))
}

fn file_search_decoder() -> Decoder(response.Tool) {
  use vector_store_ids <- decode.field(
    "vector_store_ids",
    decode.list(decode.string),
  )
  use filters <- decode.field("filters", file_search_filter_decoder())
  use max_num_results <- decode.field("max_num_results", decode.int)
  use ranking_options <- decode.field(
    "ranking_options",
    ranking_options_decoder(),
  )
  decode.success(response.FileSearch(
    vector_store_ids:,
    filters:,
    max_num_results:,
    ranking_options:,
  ))
}

pub fn annotation_decoder() {
  let file_citation_decoder = fn() {
    use _file_citation <- decode.field("type", decode.string)
    use file_id <- decode.field("file_id", decode.string)
    use index <- decode.field("index", decode.int)
    decode.success(response.FileCitation(file_id:, index:))
  }

  let file_path_decoder = fn() {
    use _file_path <- decode.field("type", decode.string)
    use file_id <- decode.field("file_id", decode.string)
    use index <- decode.field("index", decode.int)
    decode.success(response.FilePath(file_id:, index:))
  }

  let url_citation_decoder = fn() {
    use _url_citation <- decode.field("type", decode.string)
    use end_index <- decode.field("end_index", decode.int)
    use start_index <- decode.field("start_index", decode.int)
    use title <- decode.field("title", decode.string)
    use url <- decode.field("url", decode.string)
    decode.success(response.URLCitation(end_index:, start_index:, title:, url:))
  }

  let container_file_citation_decoder = fn() {
    use _container_file_citation <- decode.field("type", decode.string)
    use container_id <- decode.field("container_id", decode.string)
    use end_index <- decode.field("end_index", decode.int)
    use file_id <- decode.field("file_id", decode.string)
    use filename <- decode.field("filename", decode.string)
    use start_index <- decode.field("start_index", decode.int)
    decode.success(response.ContainerFileCitation(
      container_id:,
      end_index:,
      file_id:,
      filename:,
      start_index:,
    ))
  }

  use type_ <- decode.field("type", decode.string)
  case type_ {
    "file_citation" -> file_citation_decoder()
    "url_citation" -> url_citation_decoder()
    "container_file_citation" -> container_file_citation_decoder()
    "file_path" -> file_path_decoder()
    _ -> {
      echo "annotation_decoder"
      panic
    }
  }
}

pub fn sources_decoder() -> Decoder(response.Sources) {
  // The type of source. Always url.
  use type_ <- decode.field("type", decode.string)
  // TODO Error or panic?
  assert type_ == "url"
  use url <- decode.field("url", decode.string)
  decode.success(response.Sources(url:))
}

fn billing_decoder() {
  use payer <- decode.field("payer", decode.string)
  decode.success(response.Billing(payer:))
}

fn error_decoder() {
  use code <- decode.field("code", decode.string)
  use message <- decode.field("message", decode.string)
  decode.success(response.Error(code:, message:))
}

fn incomplete_details_decoder() {
  use reason <- decode.field("reason", decode.string)
  decode.success(response.IncompleteDetails(reason:))
}

fn instructions_decoder() {
  decode.one_of(
    decode.string |> decode.map(fn(x) { response.InstructionsText(x) }),
    [],
  )
}

fn output_decoder() {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "message" -> {
      let output_text_decoder = fn() {
        use text <- decode.field("text", decode.string)
        use annotations <- decode.field(
          "annotations",
          decode.list(annotation_decoder()),
        )
        decode.success(response.OutputText(text:, annotations:))
      }

      let content_item_decoder = fn() {
        use type_ <- decode.field("type", decode.string)
        case type_ {
          "output_text" -> output_text_decoder()
          _ -> {
            echo type_
            panic
          }
        }
      }
      use id <- decode.field("id", decode.string)
      use status <- decode.field("status", decode.string)
      use role <- decode.field("role", decode.string)
      use content <- decode.field(
        "content",
        decode.list(content_item_decoder()),
      )
      decode.success(response.OutputMessage(content:, id:, role:, status:))
    }

    "web_search_call" -> {
      let action_decoder = fn() -> Decoder(response.Action) {
        let search_decoder = fn() {
          use query <- decode.field("query", decode.string)
          use sources <- decode.optional_field(
            "sources",
            response.Sources(url: "n/a"),
            sources_decoder(),
          )
          decode.success(response.SearchAction(query:, sources:))
        }
        use type_ <- decode.field("type", decode.string)
        case type_ {
          "search" -> search_decoder()
          _ -> {
            echo "action_decoder paniced"
            panic
          }
        }
      }

      use id <- decode.field("id", decode.string)
      use status <- decode.field("status", decode.string)
      use action <- decode.field("action", action_decoder())
      decode.success(response.OutputWebSearchCall(id:, action:, status:))
    }

    "mcp_list_tools" -> {
      let tool_item_decoder = fn() -> Decoder(response.OutputMcpListTools) {
        use description <- decode.field("description", decode.string)
        use name <- decode.field("name", decode.string)
        decode.success(response.OutputMcpToolItem(description:, name:))
      }
      use id <- decode.field("id", decode.string)
      use server_label <- decode.field("server_label", decode.string)
      use tools <- decode.field("tools", decode.list(tool_item_decoder()))
      decode.success(response.OutputMcpListTools(id:, server_label:, tools:))
    }
    "reasoning" -> {
      let summary_decoder = fn() -> Decoder(response.OutputReasoningSummary) {
        use text <- decode.field("text", decode.string)
        decode.success(response.OutputReasoningSummary(text:))
      }
      let output_reasoning_content_decoder = fn() -> Decoder(
        response.OutputReasoningContent,
      ) {
        use text <- decode.field("text", decode.string)
        decode.success(response.OutputReasoningContent(text:))
      }
      use id <- decode.field("id", decode.string)
      use summary <- decode.field("summary", decode.list(summary_decoder()))
      use content <- decode.optional_field(
        "content",
        [],
        decode.list(output_reasoning_content_decoder()),
      )
      decode.success(response.OutputReasoning(id:, summary:, content:))
    }
    "mcp_call" -> {
      let mcp_call_error_decoder = fn() -> Decoder(response.OutputMcpCallError) {
        use code <- decode.field("call", decode.int)
        use message <- decode.field("text", decode.string)
        decode.success(response.OutputMcpCallError(code:, message:))
      }
      use id <- decode.field("id", decode.string)
      use status <- decode.field("status", decode.string)
      use approval_request_id <- decode.field(
        "approval_request_id",
        decode.optional(decode.string),
      )
      use arguments <- decode.field("arguments", decode.string)
      use error <- decode.field(
        "error",
        decode.optional(mcp_call_error_decoder()),
      )
      use name <- decode.field("name", decode.string)
      use output <- decode.field("output", decode.string)
      use server_label <- decode.field("server_label", decode.string)
      decode.success(response.OutputMcpCall(
        id:,
        status:,
        approval_request_id:,
        arguments:,
        error:,
        name:,
        output:,
        server_label:,
      ))
    }
    "mcp_approval_request" -> {
      use id <- decode.field("id", decode.string)
      use arguments <- decode.field("arguments", decode.string)
      use name <- decode.field("name", decode.string)
      use server_label <- decode.field("server_label", decode.string)
      decode.success(response.OutputMcpApprovalRequest(
        id:,
        arguments:,
        name:,
        server_label:,
      ))
    }
    "function_call" -> {
      use status <- decode.field("status", decode.string)
      use id <- decode.field("id", decode.string)
      use call_id <- decode.field("call_id", decode.string)
      use name <- decode.field("name", decode.string)
      use arguments <- decode.field("arguments", decode.string)
      decode.success(response.OutputFunctionCall(
        status:,
        id:,
        call_id:,
        name:,
        arguments:,
      ))
    }

    _ -> {
      echo "output decoder case not found"
      echo type_
      panic
    }
  }
}

fn reasoning_decoder() {
  use effort <- decode.field("effort", decode.optional(decode.string))
  use summary <- decode.field("summary", decode.optional(decode.string))
  decode.success(response.Reasoning(effort:, summary:))
}

fn format_decoder() {
  use type_ <- decode.field("type", decode.string)
  decode.success(response.Format(type_:))
}

fn text_decoder() {
  use format <- decode.field("format", format_decoder())
  use verbosity <- decode.field("verbosity", decode.string)
  decode.success(response.Text(format:, verbosity:))
}

pub fn response_decoder() -> decode.Decoder(Response) {
  // TODO better error handling
  use error <- decode.field("error", decode.optional(error_decoder()))
  assert error == option.None
  use object <- decode.field("object", decode.string)
  // object is always equal to response
  assert object == "response"
  use background <- decode.field("background", decode.bool)
  use billing <- decode.field("billing", billing_decoder())
  use created_at <- decode.field("created_at", decode.int)
  use id <- decode.field("id", decode.string)
  use incomplete_details <- decode.field(
    "incomplete_details",
    decode.optional(incomplete_details_decoder()),
  )
  use instructions <- decode.field(
    "instructions",
    decode.optional(instructions_decoder()),
  )
  use max_output_tokens <- decode.field(
    "max_output_tokens",
    decode.optional(decode.int),
  )
  use max_tool_calls <- decode.field(
    "max_tool_calls",
    decode.optional(decode.int),
  )
  use model <- decode.field("model", decode.string)
  use status <- decode.field("status", decode.string)
  use output <- decode.field("output", decode.list(output_decoder()))
  use parallel_tool_calls <- decode.field("parallel_tool_calls", decode.bool)
  use previous_response_id <- decode.field(
    "previous_response_id",
    decode.optional(decode.string),
  )
  use prompt_cache_key <- decode.field(
    "prompt_cache_key",
    decode.optional(decode.string),
  )
  use reasoning <- decode.field("reasoning", reasoning_decoder())
  use safety_identifier <- decode.field(
    "safety_identifier",
    decode.optional(decode.string),
  )
  use service_tier <- decode.field("service_tier", decode.string)
  use store <- decode.field("store", decode.bool)
  use temperature <- decode.field("temperature", decode.float)
  use text <- decode.field("text", text_decoder())
  use tool_choice <- decode.field("tool_choice", decode.string)
  use tools <- decode.field("tools", decode.list(tool_decoder()))
  use top_logprobs <- decode.field("top_logprobs", decode.int)
  use top_p <- decode.field("top_p", decode.float)
  use truncation <- decode.field("truncation", decode.string)
  use usage <- decode.field("usage", usage_decoder())
  use user <- decode.field("user", decode.optional(decode.string))
  use metadata <- decode.field(
    "metadata",
    decode.dict(decode.string, decode.string),
  )

  decode.success(Response(
    background:,
    id:,
    object:,
    created_at:,
    status:,
    billing:,
    error:,
    incomplete_details:,
    instructions:,
    max_output_tokens:,
    max_tool_calls:,
    model:,
    output:,
    parallel_tool_calls:,
    previous_response_id:,
    prompt_cache_key:,
    reasoning:,
    safety_identifier:,
    service_tier:,
    store:,
    temperature:,
    text:,
    tool_choice:,
    tools:,
    top_logprobs:,
    top_p:,
    truncation:,
    usage:,
    user:,
    metadata:,
  ))
}
// "{\n  \"id\": \"resp_0b891a9e705bb91200693df1375f0481999dc23f0fb588d14d\",\n  \"object\": \"response\",\n  \"created_at\": 1765667127,\n  \"status\": \"completed\",\n  \"background\": false,\n  \"billing\": {\n    \"payer\": \"developer\"\n  },\n  \"error\": null,\n  \"incomplete_details\": null,\n  \"instructions\": null,\n  \"max_output_tokens\": null,\n  \"max_tool_calls\": null,\n  \"model\": \"gpt-5-2025-08-07\",\n  \"output\": [\n    {\n      \"id\": \"rs_0b891a9e705bb91200693df138c8288199b9b5ffeb4c27094b\",\n      \"type\": \"reasoning\",\n      \"summary\": []\n    },\n    {\n      \"id\": \"fc_0b891a9e705bb91200693df13d58dc8199b2a3fe0052e19e05\",\n      \"type\": \"function_call\",\n      \"status\": \"completed\",\n      \"arguments\": \"{\\\"sign\\\":\\\"Cancer\\\"}\",\n      \"call_id\": \"call_Tp0JRxPnynWzIpkwIV7ge3OB\",\n      \"name\": \"get_horoscope\"\n    }\n  ],\n  \"parallel_tool_calls\": true,\n  \"previous_response_id\": null,\n  \"prompt_cache_key\": null,\n  \"prompt_cache_retention\": null,\n  \"reasoning\": {\n    \"effort\": \"medium\",\n    \"summary\": null\n  },\n  \"safety_identifier\": null,\n  \"service_tier\": \"default\",\n  \"store\": true,\n  \"temperature\": 1.0,\n  \"text\": {\n    \"format\": {\n      \"type\": \"text\"\n    },\n    \"verbosity\": \"medium\"\n  },\n  \"tool_choice\": \"auto\",\n  \"tools\": [\n    {\n      \"type\": \"function\",\n      \"description\": \"Get today's horoscope for an astrological sign\",\n      \"name\": \"get_horoscope\",\n      \"parameters\": {\n        \"type\": \"object\",\n        \"properties\": {\n          \"sign\": {\n            \"type\": \"string\",\n            \"description\": \"An astrological sign like Taurus or Aquarius\"\n          }\n        },\n        \"required\": [\n          \"sign\"\n        ],\n        \"additionalProperties\": false\n      },\n      \"strict\": true\n    }\n  ],\n  \"top_logprobs\": 0,\n  \"top_p\": 1.0,\n  \"truncation\": \"disabled\",\n  \"usage\": {\n    \"input_tokens\": 67,\n    \"input_tokens_details\": {\n      \"cached_tokens\": 0\n    },\n    \"output_tokens\": 150,\n    \"output_tokens_details\": {\n      \"reasoning_tokens\": 128\n    },\n    \"total_tokens\": 217\n  },\n  \"user\": null,\n  \"metadata\": {}\n}"
// src/openai/responses/decoders.gleam:434
// "output decoder case not found"
// src/openai/responses/decoders.gleam:435
// "function_call"
