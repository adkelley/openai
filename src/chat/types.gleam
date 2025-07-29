import gleam/option.{type Option}

// Audio
pub type Audio {
  Audio(data: String, expires_at: Int, id: String, transcript: String)
}

// Message roles in chat
pub type Role {
  System
  User
  Assistant
  Tool
  OtherRole(String)
}

pub type UrlCitation {
  UrlCitation(end_index: Int, start_index: Int, title: String, url: String)
}

pub type Annotation {
  Annotation(type_: String, url_citation: UrlCitation)
}

pub type Function {
  Function(arguments: String, name: String)
}

pub type ToolCall {
  ToolCall(function: Function, id: String, type_: String)
}

// Message object in a choice
pub type Message {
  Message(
    role: Role,
    content: String,
    tool_calls: Option(List(ToolCall)),
    refusal: Option(String),
    annotations: List(Annotation),
    audio: Option(Audio),
  )
}

pub type BytesLogprobToken {
  BytesLogprobToken(bytes: Option(List(Int)), logprob: Float, token: String)
}

pub type Content {
  Content(
    bytes: Option(List(Int)),
    logprob: Float,
    token: String,
    top_logprobs: List(BytesLogprobToken),
  )
}

pub type Refusal {
  Refusal(
    bytes: Option(List(Int)),
    logprob: Float,
    token: String,
    top_logprobs: List(BytesLogprobToken),
  )
}

pub type Logprob {
  Logprob(content: List(Content), refusal: List(Refusal))
}

// One result choice from the completions
pub type CompletionChoice {
  CompletionChoice(
    index: Int,
    message: Message,
    finish_reason: String,
    logprobs: Option(Logprob),
  )
}

pub type CompletionTokenDetails {
  CompletionTokenDetails(
    accepted_prediction_tokens: Int,
    audio_tokens: Int,
    reasoning_tokens: Int,
    rejected_prediction_tokens: Int,
  )
}

pub type PromptTokenDetails {
  PromptTokenDetails(cached_tokens: Int, audio_tokens: Int)
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

// Full response from OpenAI /v1/chat/completions
pub type Completion {
  Completion(
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
