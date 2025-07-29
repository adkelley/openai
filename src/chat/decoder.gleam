import chat/types
import gleam/dynamic/decode
import gleam/option.{None, Some}

fn role_type_decoder() {
  use role_string <- decode.then(decode.string)
  case role_string {
    "assistant" -> decode.success(types.Assistant)
    "user" -> decode.success(types.User)
    "system" -> decode.success(types.System)
    "tool" -> decode.success(types.Tool)
    _ -> decode.success(types.OtherRole(role_string))
  }
}

fn url_citation_type_decoder() {
  use end_index <- decode.field("end_index", decode.int)
  use start_index <- decode.field("start_index", decode.int)
  use title <- decode.field("title", decode.string)
  use url <- decode.field("url", decode.string)
  decode.success(types.UrlCitation(end_index:, start_index:, title:, url:))
}

fn annotation_decoder() {
  use type_ <- decode.field("type", decode.string)
  use url_citation <- decode.field("url_citation", url_citation_type_decoder())
  decode.success(types.Annotation(type_:, url_citation:))
}

fn audio_type_decoder() {
  use data <- decode.field("data", decode.string)
  use expires_at <- decode.field("expires_at", decode.int)
  use id <- decode.field("id", decode.string)
  use transcript <- decode.field("transcript", decode.string)
  decode.success(Some(types.Audio(data:, expires_at:, id:, transcript:)))
}

fn function_decoder() {
  use arguments <- decode.field("arguments", decode.string)
  use name <- decode.field("name", decode.string)
  decode.success(types.Function(arguments:, name:))
}

fn tool_call_decoder() {
  use function <- decode.field("function", function_decoder())
  use id <- decode.field("id", decode.string)
  use type_ <- decode.field("type", decode.string)
  decode.success(types.ToolCall(function:, id:, type_:))
}

fn message_decoder() {
  let tool_calls_decoder = decode.optional(decode.list(tool_call_decoder()))
  use role <- decode.field("role", role_type_decoder())
  use content <- decode.field("content", decode.string)
  use refusal <- decode.field("refusal", decode.optional(decode.string))
  use audio <- decode.optional_field("audio", None, audio_type_decoder())
  use annotations <- decode.field(
    "annotations",
    decode.list(annotation_decoder()),
  )
  use tool_calls <- decode.optional_field(
    "tool_calls",
    None,
    tool_calls_decoder,
  )
  decode.success(types.Message(
    role:,
    content:,
    refusal:,
    annotations:,
    audio:,
    tool_calls:,
  ))
}

fn blt_decoder() {
  use bytes <- decode.field("bytes", decode.optional(decode.list(decode.int)))
  use logprob <- decode.field("logprob", decode.float)
  use token <- decode.field("token", decode.string)
  decode.success(types.BytesLogprobToken(bytes:, logprob:, token:))
}

fn refusal_decoder() {
  use bytes <- decode.field("bytes", decode.optional(decode.list(decode.int)))
  use logprob <- decode.field("logprob", decode.float)
  use token <- decode.field("token", decode.string)
  use top_logprobs <- decode.field("top_logprobs", decode.list(blt_decoder()))
  decode.success(types.Refusal(bytes:, logprob:, token:, top_logprobs:))
}

fn content_decoder() {
  use bytes <- decode.field("bytes", decode.optional(decode.list(decode.int)))
  use logprob <- decode.field("logprob", decode.float)
  use token <- decode.field("token", decode.string)
  use top_logprobs <- decode.field("top_logprobs", decode.list(blt_decoder()))
  decode.success(types.Content(bytes:, logprob:, token:, top_logprobs:))
}

fn logprob_decoder() {
  use content <- decode.field("content", decode.list(content_decoder()))
  use refusal <- decode.field("refusal", decode.list(refusal_decoder()))
  decode.success(types.Logprob(content:, refusal:))
}

fn completion_choice_decoder() {
  use finish_reason <- decode.field("finish_reason", decode.string)
  use index <- decode.field("index", decode.int)
  use logprobs <- decode.field("logprobs", decode.optional(logprob_decoder()))
  use message <- decode.field("message", message_decoder())
  decode.success(types.CompletionChoice(
    index:,
    message:,
    finish_reason:,
    logprobs:,
  ))
}

fn completion_tokens_details_decoder() {
  use accepted_prediction_tokens <- decode.field(
    "accepted_prediction_tokens",
    decode.int,
  )
  use audio_tokens <- decode.field("audio_tokens", decode.int)
  use reasoning_tokens <- decode.field("reasoning_tokens", decode.int)
  use rejected_prediction_tokens <- decode.field(
    "rejected_prediction_tokens",
    decode.int,
  )
  decode.success(types.CompletionTokenDetails(
    accepted_prediction_tokens:,
    audio_tokens:,
    reasoning_tokens:,
    rejected_prediction_tokens:,
  ))
}

fn prompt_tokens_details_decoder() {
  use cached_tokens <- decode.field("cached_tokens", decode.int)
  use audio_tokens <- decode.field("audio_tokens", decode.int)
  decode.success(types.PromptTokenDetails(cached_tokens:, audio_tokens:))
}

fn usage_decoder() {
  use completion_tokens <- decode.field("completion_tokens", decode.int)
  use prompt_tokens <- decode.field("prompt_tokens", decode.int)
  use total_tokens <- decode.field("total_tokens", decode.int)
  use prompt_tokens_details <- decode.field(
    "prompt_tokens_details",
    prompt_tokens_details_decoder(),
  )
  use completion_tokens_details <- decode.field(
    "completion_tokens_details",
    completion_tokens_details_decoder(),
  )
  decode.success(types.Usage(
    prompt_tokens:,
    completion_tokens:,
    total_tokens:,
    completion_tokens_details:,
    prompt_tokens_details:,
  ))
}

pub fn chat_completion_decoder() {
  use id <- decode.field("id", decode.string)
  use object <- decode.field("object", decode.string)
  use created <- decode.field("created", decode.int)
  use choices <- decode.field(
    "choices",
    decode.list(completion_choice_decoder()),
  )
  use usage <- decode.field("usage", usage_decoder())
  use model <- decode.field("model", decode.string)
  use service_tier <- decode.field("service_tier", decode.string)
  use system_fingerprint <- decode.field("system_fingerprint", decode.string)
  decode.success(types.Completion(
    choices:,
    id:,
    object:,
    created:,
    model:,
    service_tier:,
    system_fingerprint:,
    usage:,
  ))
}
