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

pub fn web_search_decoder() {
  use type_ <- decode.field("type", decode.string)
  assert type_ == "web_search"
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

fn ranking_options_decoder() -> Decoder(response.RankingOptions) {
  use ranker <- decode.field("ranker", decode.string)
  use score_threshold <- decode.field("score_threshold", decode.float)
  decode.success(response.RankingOptions(ranker:, score_threshold:))
}

fn function_decoder() {
  use name <- decode.field("name", decode.string)
  use parameters <- decode.field("parameters", decode.string)
  use strict <- decode.field("strict", decode.bool)
  use description <- decode.field("description", decode.optional(decode.string))
  decode.success(response.Function(name:, parameters:, strict:, description:))
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

pub fn tool_decoder() -> Decoder(response.Tool) {
  decode.one_of(function_decoder(), or: [
    file_search_decoder(),
    computer_use_decoder(),
    web_search_decoder(),
  ])
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

fn file_citation_decoder() {
  use file_id <- decode.field("file_id", decode.string)
  use index <- decode.field("index", decode.int)
  decode.success(response.FileCitation(file_id:, index:))
}

fn url_citation_decoder() {
  use end_index <- decode.field("end_index", decode.int)
  use start_index <- decode.field("start_index", decode.int)
  use title <- decode.field("title", decode.string)
  use url <- decode.field("url", decode.string)
  decode.success(response.URLCitation(end_index:, start_index:, title:, url:))
}

fn container_file_citation_decoder() {
  todo
}

fn file_path_decoder() {
  use file_id <- decode.field("file_id", decode.string)
  use index <- decode.field("index", decode.int)
  decode.success(response.FilePath(file_id:, index:))
}

pub fn annotation_decoder() {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "file_citation" -> file_citation_decoder()
    "url_citation" -> url_citation_decoder()
    "container_file_citation" -> container_file_citation_decoder()
    "file_path" -> file_path_decoder()
    _ -> panic
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
  case type_ {
    "message" -> {
      use id <- decode.field("id", decode.string)
      use status <- decode.field("status", decode.string)
      use role <- decode.field("role", decode.string)
      use content <- decode.field(
        "content",
        decode.list(content_item_decoder()),
      )
      decode.success(response.Message(content:, id:, role:, status:))
    }
    "web_search_call" -> {
      use id <- decode.field("id", decode.string)
      use status <- decode.field("status", decode.string)
      use action <- decode.field("action", action_decoder())
      decode.success(response.WebSearchCall(id:, action:, status:))
    }

    _ -> {
      echo "output not found"
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

pub fn action_decoder() -> Decoder(response.Action) {
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

pub fn response_decoder() -> decode.Decoder(Response) {
  // TODO better error handling
  use error <- decode.field("error", decode.optional(error_decoder()))
  assert error == option.None
  use object <- decode.field("object", decode.string)
  // object is always equal to response
  assert object == "response"
  use background <- decode.field("background", decode.bool)
  use id <- decode.field("id", decode.string)
  use created_at <- decode.field("created_at", decode.int)
  use status <- decode.field("status", decode.string)
  use billing <- decode.field("billing", billing_decoder())
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
  use tools <- decode.field("tools", decode.list(web_search_decoder()))
  use top_logprobs <- decode.field("top_logprobs", decode.int)
  use top_p <- decode.field("top_p", decode.float)
  use truncation <- decode.field("truncation", decode.string)
  use usage <- decode.field("usage", usage_decoder())
  use user <- decode.field("user", decode.optional(decode.string))
  use metadata <- decode.field(
    "metadata",
    decode.dict(decode.string, decode.string),
  )
  // echo "metadata"

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
// Ok(Response(400, [#("connection", "close"), #("date", "Thu, 16 Oct 2025 22:16:53 GMT"), #("server", "cloudflare"), #("content-length", "280"), #("content-type", "application/json"), #("openai-version", "2020-10-01"), #("openai-organization", "adkpartners"), #("openai-project", "proj_owLw0yGl71UIfzp1TWZB7P10"), #("x-request-id", "req_32f104ee71364674a9fb9d7253137a58"), #("openai-processing-ms", "21"), #("x-envoy-upstream-service-time", "25"), #("cf-cache-status", "DYNAMIC"), #("set-cookie", "__cf_bm=HBspPcMhnyR_LVCBv4eiN98vOgugJy8QbNdaZgpCxcQ-1760653013-1.0.1.1-xjcO5il36WDjXgVq3URIrwga.pFF80TkTM2liY9cLFz8iQWBZbGnsc9TnkzrYUhwQdfFevc5XQa5WhTzQraWpV3WHZC8qXrGeQ92Gak9hFo; path=/; expires=Thu, 16-Oct-25 22:46:53 GMT; domain=.api.openai.com; HttpOnly; Secure; SameSite=None"), #("strict-transport-security", "max-age=31536000; includeSubDomains; preload"), #("x-content-type-options", "nosniff"), #("set-cookie", "_cfuvid=ZYBmKhVNgSzshmPFet.Qx_erJe.qfDzHlx_n5RFT34U-1760653013688-0.0.1.1-604800000; path=/; domain=.api.openai.com; HttpOnly; Secure; SameSite=None"), #("cf-ray", "98faec56cfd406ad-SJC"), #("alt-svc", "h3=\":443\"; ma=86400")], "{\n  \"error\": {\n    \"message\": \"Invalid 'tools[0].filters.allowed_domains': empty array. Expected an array with minimum length 1, but got an empty array instead.\",\n    \"type\": \"invalid_request_error\",\n    \"param\": \"tools[0].filters.allowed_domains\",\n    \"code\": \"empty_array\"\n  }\n}"))
