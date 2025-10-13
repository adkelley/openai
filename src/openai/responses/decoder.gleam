import gleam/dynamic/decode
import gleam/option.{None, Some}
import openai/responses/types/response.{type Response, Response}
import openai/shared/types as shared

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

fn file_citation_decoder() {
  todo
}

fn url_citation_decoder() {
  todo
}

fn container_file_citation_decoder() {
  todo
}

fn file_path_decoder() {
  todo
}

fn annotation_decoder() {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "file_citation" -> file_citation_decoder()
    "url_citation" -> url_citation_decoder()
    "container_file_citation" -> container_file_citation_decoder()
    "file_path" -> file_path_decoder()
    _ -> panic
  }
}

fn output_text_decoder() {
  use text <- decode.field("text", decode.string)
  use annotations <- decode.field(
    "annotations",
    decode.list(annotation_decoder()),
  )
  decode.success(response.OutputText(text:, annotations:))
}

fn content_item_decoder() {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "output_text" -> output_text_decoder()
    _ -> panic
  }
}

fn output_decoder() {
  use type_ <- decode.field("type", decode.string)
  use id <- decode.field("id", decode.string)
  use status <- decode.field("status", decode.string)
  use role <- decode.field("role", decode.string)
  use content <- decode.field("content", decode.list(content_item_decoder()))
  case type_ {
    "message" -> decode.success(response.Message(content:, id:, role:, status:))
    _ -> panic
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

fn function_decoder() {
  use name <- decode.field("name", decode.string)
  use parameters <- decode.field("parameters", decode.string)
  use strict <- decode.field("strict", decode.bool)
  use description <- decode.field("description", decode.optional(decode.string))
  decode.success(response.Function(name:, parameters:, strict:, description:))
}

// fn file_search_filter_decoder() {
//   todo
// }

// fn ranking_options_decoder() {
//   decode.string
// }

// fn file_search_decoder() {
//   use _type_ <- decode.field("type", decode.string)
//   use vector_store_ids <- decode.field(
//     "vector_store_ids",
//     decode.list(decode.string),
//   )
//   use filters <- decode.field("filters", file_search_filter_decoder())
//   use max_num_results <- decode.field("max_num_results", decode.int)
//   use ranking_options <- decode.field(
//     "ranking_options",
//     ranking_options_decoder(),
//   )
//   decode.success(response.FileSearch(
//     vector_store_ids:,
//     filters:,
//     max_num_results:,
//     ranking_options:,
//   ))
// }

// fn environment_decoder() {
//   decode.string
// }

// fn computer_use_decoder() {
//   use display_height <- decode.field("display_height", decode.int)
//   use display_width <- decode.field("display_width", decode.int)
//   use environment <- decode.field("environment", environment_decoder())
//   decode.success(response.ComputerUse(
//     display_height:,
//     display_width:,
//     environment:,
//   ))
// }

// fn search_context_size_decoder() {
//   decode.string
// }

// fn user_location_decoder() {
//   decode.string
// }

// fn web_search_decoder() {
//   use search_context_size <- decode.field(
//     "search_context_size",
//     search_context_size_decoder(),
//   )

//   use user_location <- decode.field(
//     "user_location",
//     decode.optional(user_location_decoder()),
//   )
//   decode.success(response.WebSearch(search_context_size:, user_location:))
// }

fn tool_decoder() {
  decode.one_of(function_decoder(), or: [
    // file_search_decoder(),
  // computer_use_decoder(),
  // web_search_decoder(),
  ])
}

fn usage_decoder() {
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

pub fn response_decoder() -> decode.Decoder(Response) {
  use background <- decode.field("background", decode.bool)
  use id <- decode.field("id", decode.string)
  use object <- decode.field("object", decode.string)
  // object is always equal to response
  assert object == "response"
  use created_at <- decode.field("created_at", decode.int)
  use status <- decode.field("status", decode.string)
  use billing <- decode.field("billing", billing_decoder())
  use error <- decode.field("error", decode.optional(error_decoder()))
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
