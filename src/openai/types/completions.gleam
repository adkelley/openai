// https://platform.openai.com/docs/api-reference/chat
// 
import gleam/dynamic/decode
import gleam/option.{type Option, None, Some}
import openai/types/shared

pub type Config {
  Config(name: shared.ResponsesModel, temperature: Float, stream: Bool)
}

// Audio
pub type Audio {
  Audio(data: String, expires_at: Int, id: String, transcript: String)
}

fn decode_audio() {
  use data <- decode.field("data", decode.string)
  use expires_at <- decode.field("expires_at", decode.int)
  use id <- decode.field("id", decode.string)
  use transcript <- decode.field("transcript", decode.string)
  decode.success(Some(Audio(data:, expires_at:, id:, transcript:)))
}

pub type UrlCitation {
  UrlCitation(end_index: Int, start_index: Int, title: String, url: String)
}

fn decode_url_citation_type() {
  use end_index <- decode.field("end_index", decode.int)
  use start_index <- decode.field("start_index", decode.int)
  use title <- decode.field("title", decode.string)
  use url <- decode.field("url", decode.string)
  decode.success(UrlCitation(end_index:, start_index:, title:, url:))
}

pub type Annotation {
  Annotation(type_: String, url_citation: UrlCitation)
}

fn decode_annotation() {
  use type_ <- decode.field("type", decode.string)
  use url_citation <- decode.field("url_citation", decode_url_citation_type())
  decode.success(Annotation(type_:, url_citation:))
}

pub type Function {
  Function(arguments: String, name: String)
}

fn decode_function() {
  use arguments <- decode.field("arguments", decode.string)
  use name <- decode.field("name", decode.string)
  decode.success(Function(arguments:, name:))
}

pub type ToolCall {
  ToolCall(function: Function, id: String, type_: String)
}

fn decode_tool_call() {
  use function <- decode.field("function", decode_function())
  use id <- decode.field("id", decode.string)
  use type_ <- decode.field("type", decode.string)
  decode.success(ToolCall(function:, id:, type_:))
}

// Message object in a choice
pub type Message {
  Message(
    role: shared.Role,
    content: String,
    tool_calls: Option(List(ToolCall)),
    refusal: Option(String),
    annotations: List(Annotation),
    audio: Option(Audio),
  )
}

fn decode_message() {
  let tool_calls_decoder = decode.optional(decode.list(decode_tool_call()))
  use role <- decode.field("role", shared.decode_role())
  use content <- decode.field("content", decode.string)
  use refusal <- decode.field("refusal", decode.optional(decode.string))
  use audio <- decode.optional_field("audio", None, decode_audio())
  use annotations <- decode.field(
    "annotations",
    decode.list(decode_annotation()),
  )
  use tool_calls <- decode.optional_field(
    "tool_calls",
    None,
    tool_calls_decoder,
  )
  decode.success(Message(
    role:,
    content:,
    refusal:,
    annotations:,
    audio:,
    tool_calls:,
  ))
}

pub type Messages =
  List(Message)

pub type BytesLogprobToken {
  BytesLogprobToken(bytes: Option(List(Int)), logprob: Float, token: String)
}

fn decode_bytes_logprob_token() {
  use bytes <- decode.field("bytes", decode.optional(decode.list(decode.int)))
  use logprob <- decode.field("logprob", decode.float)
  use token <- decode.field("token", decode.string)
  decode.success(BytesLogprobToken(bytes:, logprob:, token:))
}

pub type Content {
  Content(
    bytes: Option(List(Int)),
    logprob: Float,
    token: String,
    top_logprobs: List(BytesLogprobToken),
  )
}

fn decode_content() {
  use bytes <- decode.field("bytes", decode.optional(decode.list(decode.int)))
  use logprob <- decode.field("logprob", decode.float)
  use token <- decode.field("token", decode.string)
  use top_logprobs <- decode.field(
    "top_logprobs",
    decode.list(decode_bytes_logprob_token()),
  )
  decode.success(Content(bytes:, logprob:, token:, top_logprobs:))
}

pub type Refusal {
  Refusal(
    bytes: Option(List(Int)),
    logprob: Float,
    token: String,
    top_logprobs: List(BytesLogprobToken),
  )
}

fn decode_refusal() {
  use bytes <- decode.field("bytes", decode.optional(decode.list(decode.int)))
  use logprob <- decode.field("logprob", decode.float)
  use token <- decode.field("token", decode.string)
  use top_logprobs <- decode.field(
    "top_logprobs",
    decode.list(decode_bytes_logprob_token()),
  )
  decode.success(Refusal(bytes:, logprob:, token:, top_logprobs:))
}

pub type Logprobs {
  Logprob(content: List(Content), refusal: List(Refusal))
}

fn decode_logprobs() {
  use content <- decode.field("content", decode.list(decode_content()))
  use refusal <- decode.field("refusal", decode.list(decode_refusal()))
  decode.success(Logprob(content:, refusal:))
}

// One result choice from the completions
pub type CompletionChoice {
  CompletionChoice(
    index: Int,
    message: Message,
    finish_reason: Option(String),
    logprobs: Option(Logprobs),
  )
}

fn decode_completion_choice() {
  // use finish_reason <- decode.field("finish_reason", decode.string)
  use finish_reason <- decode.field(
    "finish_reason",
    decode.optional(decode.string),
  )
  use index <- decode.field("index", decode.int)
  use logprobs <- decode.field("logprobs", decode.optional(decode_logprobs()))
  use message <- decode.field("message", decode_message())
  decode.success(CompletionChoice(index:, message:, finish_reason:, logprobs:))
}

pub type CompletionTokenDetails {
  CompletionTokenDetails(
    accepted_prediction_tokens: Int,
    audio_tokens: Int,
    reasoning_tokens: Int,
    rejected_prediction_tokens: Int,
  )
}

fn decode_completion_tokens_details() {
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
  decode.success(CompletionTokenDetails(
    accepted_prediction_tokens:,
    audio_tokens:,
    reasoning_tokens:,
    rejected_prediction_tokens:,
  ))
}

pub type PromptTokenDetails {
  PromptTokenDetails(cached_tokens: Int, audio_tokens: Int)
}

fn decode_prompt_tokens_details() {
  use cached_tokens <- decode.field("cached_tokens", decode.int)
  use audio_tokens <- decode.field("audio_tokens", decode.int)
  decode.success(PromptTokenDetails(cached_tokens:, audio_tokens:))
}

// Usage breakdown
pub type Usage {
  Usage(
    prompt_tokens: Int,
    completion_tokens: Int,
    total_tokens: Int,
    completion_tokens_details: CompletionTokenDetails,
    prompt_tokens_details: PromptTokenDetails,
  )
}

fn decode_usage() {
  use completion_tokens <- decode.field("completion_tokens", decode.int)
  use prompt_tokens <- decode.field("prompt_tokens", decode.int)
  use total_tokens <- decode.field("total_tokens", decode.int)
  use prompt_tokens_details <- decode.field(
    "prompt_tokens_details",
    decode_prompt_tokens_details(),
  )
  use completion_tokens_details <- decode.field(
    "completion_tokens_details",
    decode_completion_tokens_details(),
  )
  decode.success(Usage(
    prompt_tokens:,
    completion_tokens:,
    total_tokens:,
    completion_tokens_details:,
    prompt_tokens_details:,
  ))
}

// Full response from OpenAI /v1/chat/completions
pub type ChatCompletion {
  ChatCompletion(
    id: String,
    object: String,
    created: Int,
    model: String,
    choices: List(CompletionChoice),
    usage: Usage,
    service_tier: String,
    system_fingerprint: String,
  )
}

pub fn decode_chat_completion() {
  use id <- decode.field("id", decode.string)
  use object <- decode.field("object", decode.string)
  use created <- decode.field("created", decode.int)
  use choices <- decode.field(
    "choices",
    decode.list(decode_completion_choice()),
  )
  use usage <- decode.field("usage", decode_usage())
  use model <- decode.field("model", decode.string)
  use service_tier <- decode.field("service_tier", decode.string)
  use system_fingerprint <- decode.field("system_fingerprint", decode.string)
  decode.success(ChatCompletion(
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

// region:    ---  streamed response from OpenAI /v1/chat/completions
pub type Delta {
  Delta(role: String, content: String)
}

fn decode_delta() {
  // use finish_reason <- decode.field("finish_reason", decode.string)
  use role <- decode.optional_field("role", "assistant", decode.string)
  use content <- decode.optional_field("content", "", decode.string)
  decode.success(Delta(content:, role:))
}

pub type CompletionChoiceChunk {
  CompletionChoiceChunk(
    index: Int,
    delta: Delta,
    logprobs: Option(Logprobs),
    finish_reason: Option(String),
  )
}

fn decode_completion_choice_chunk() {
  // use finish_reason <- decode.field("finish_reason", decode.string)
  use index <- decode.field("index", decode.int)
  use delta <- decode.field("delta", decode_delta())
  use logprobs <- decode.field("logprobs", decode.optional(decode_logprobs()))
  use finish_reason <- decode.field(
    "finish_reason",
    decode.optional(decode.string),
  )
  decode.success(CompletionChoiceChunk(
    index:,
    delta:,
    logprobs:,
    finish_reason:,
  ))
}

pub type CompletionChunk {
  CompletionChunk(
    id: String,
    object: String,
    created: Int,
    model: String,
    choices: List(CompletionChoiceChunk),
    service_tier: String,
    system_fingerprint: String,
    obfuscation: String,
  )
}

pub fn decode_completion_chunk() {
  use id <- decode.field("id", decode.string)
  use object <- decode.field("object", decode.string)
  use created <- decode.field("created", decode.int)
  use choices <- decode.field(
    "choices",
    decode.list(decode_completion_choice_chunk()),
  )
  use model <- decode.field("model", decode.string)
  use service_tier <- decode.field("service_tier", decode.string)
  use obfuscation <- decode.field("obfuscation", decode.string)
  use system_fingerprint <- decode.field("system_fingerprint", decode.string)
  decode.success(CompletionChunk(
    choices:,
    id:,
    object:,
    created:,
    model:,
    service_tier:,
    system_fingerprint:,
    obfuscation:,
  ))
}
// endregion: ---  streamed response from OpenAI /v1/chat/completions
