import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import openai/types/helpers
import openai/types/logprob.{type LogProb}

pub type CreateTranscription {
  CreateTranscription(
    file: String,
    model: String,
    // TODO support VadConfig as a chunking_strategy
    chunking_strategy: Option(String),
    include: Option(List(TranscriptionInclude)),
    known_speaker_names: Option(List(String)),
    known_speaker_references: Option(List(String)),
    language: Option(String),
    prompt: Option(String),
    stream: Option(Bool),
    temperature: Option(Float),
    timestamp_granularities: Option(List(TimestampGranularities)),
  )
}

pub fn new() -> CreateTranscription {
  CreateTranscription(
    file: "",
    model: "gpt-4o-transcribe",
    chunking_strategy: None,
    include: None,
    known_speaker_names: None,
    known_speaker_references: None,
    language: None,
    prompt: None,
    stream: None,
    temperature: None,
    timestamp_granularities: None,
  )
}

pub fn with_file(
  create_transcription: CreateTranscription,
  file: String,
) -> CreateTranscription {
  CreateTranscription(..create_transcription, file: file)
}

pub fn with_model(
  create_transcription: CreateTranscription,
  model: String,
) -> CreateTranscription {
  CreateTranscription(..create_transcription, model: model)
}

pub fn with_chunking_strategy(
  create_transcription: CreateTranscription,
  chunking_strategy: String,
) -> CreateTranscription {
  CreateTranscription(
    ..create_transcription,
    chunking_strategy: Some(chunking_strategy),
  )
}

pub fn with_include(
  create_transcription: CreateTranscription,
  include: List(TranscriptionInclude),
) -> CreateTranscription {
  CreateTranscription(..create_transcription, include: Some(include))
}

pub fn with_known_speaker_names(
  create_transcription: CreateTranscription,
  known_speaker_names: List(String),
) -> CreateTranscription {
  CreateTranscription(
    ..create_transcription,
    known_speaker_names: Some(known_speaker_names),
  )
}

pub fn with_known_speaker_references(
  create_transcription: CreateTranscription,
  known_speaker_references: List(String),
) -> CreateTranscription {
  CreateTranscription(
    ..create_transcription,
    known_speaker_references: Some(known_speaker_references),
  )
}

pub fn with_language(
  create_transcription: CreateTranscription,
  language: String,
) -> CreateTranscription {
  CreateTranscription(..create_transcription, language: Some(language))
}

pub fn with_prompt(
  create_transcription: CreateTranscription,
  prompt: String,
) -> CreateTranscription {
  CreateTranscription(..create_transcription, prompt: Some(prompt))
}

pub fn with_stream(
  create_transcription: CreateTranscription,
  stream: Bool,
) -> CreateTranscription {
  CreateTranscription(..create_transcription, stream: Some(stream))
}

pub fn with_temperature(
  create_transcription: CreateTranscription,
  temperature: Float,
) -> CreateTranscription {
  CreateTranscription(..create_transcription, temperature: Some(temperature))
}

pub fn with_timestamp_granularities(
  create_transcription: CreateTranscription,
  timestamp_granularities: List(TimestampGranularities),
) -> CreateTranscription {
  CreateTranscription(
    ..create_transcription,
    timestamp_granularities: Some(timestamp_granularities),
  )
}

pub fn encode_create_transcription(
  create_transcription: CreateTranscription,
) -> Json {
  [
    #("model", json.string(create_transcription.model)),
  ]
  |> helpers.encode_option(
    "chunking_strategy",
    create_transcription.chunking_strategy,
    json.string,
  )
  |> helpers.encode_option_list(
    "include",
    create_transcription.include,
    encode_transcription_include,
  )
  |> helpers.encode_option_list(
    "known_speaker_names",
    create_transcription.known_speaker_names,
    json.string,
  )
  |> helpers.encode_option_list(
    "known_speaker_references",
    create_transcription.known_speaker_references,
    json.string,
  )
  |> helpers.encode_option(
    "language",
    create_transcription.language,
    json.string,
  )
  |> helpers.encode_option("prompt", create_transcription.prompt, json.string)
  |> helpers.encode_option("stream", create_transcription.stream, json.bool)
  |> helpers.encode_option(
    "temperature",
    create_transcription.temperature,
    json.float,
  )
  |> helpers.encode_option_list(
    "timestamp_granularities",
    create_transcription.timestamp_granularities,
    encode_timestamp_granularities,
  )
  |> json.object
}

pub type TranscriptionInclude {
  LogProbs
}

fn encode_transcription_include(
  transcription_include: TranscriptionInclude,
) -> Json {
  json.string(describe_transcription_include(transcription_include))
}

pub fn describe_transcription_include(
  transcription_include: TranscriptionInclude,
) -> String {
  case transcription_include {
    LogProbs -> "logprobs"
  }
}

pub type TimestampGranularities {
  Word
  Segment
}

fn encode_timestamp_granularities(granularities: TimestampGranularities) -> Json {
  describe_timestamp_granularity(granularities)
  |> json.string
}

pub fn describe_timestamp_granularity(
  granularities: TimestampGranularities,
) -> String {
  case granularities {
    Word -> "word"
    Segment -> "segment"
  }
}

/// Represents a transcription response returned by a model for the provided
/// audio input.
pub type Transcription {
  Transcription(
    /// The transcribed text.
    text: String,
    /// Log probability information for tokens in the transcription.
    logprobs: Option(List(LogProb)),
    /// Usage statistics for the request.
    usage: Usage,
  )
}

pub fn encode_transcription(transcription: Transcription) -> Json {
  [
    #("text", json.string(transcription.text)),
    #("usage", encode_usage(transcription.usage)),
  ]
  |> helpers.encode_option_list(
    "logprobs",
    transcription.logprobs,
    logprob.encode_logprob,
  )
  |> json.object
}

pub fn decode_transcription() -> Decoder(Transcription) {
  use text <- decode.field("text", decode.string)
  use logprobs <- decode.optional_field(
    "logprobs",
    option.None,
    decode.optional(decode.list(logprob.decode_logprob())),
  )
  use usage <- decode.field("usage", decode_usage())
  decode.success(Transcription(text:, logprobs:, usage:))
}

pub type Usage {
  /// Usage statistics for models billed by token usage.
  TokenUsage(TokenUsageDef)
  /// Usage statistics for models billed by audio input duration.
  DurationUsage(DurationUsageDef)
}

pub fn encode_usage(usage: Usage) -> Json {
  case usage {
    TokenUsage(token_usage) -> encode_token_usage(token_usage)
    DurationUsage(duration_usage) -> encode_duration_usage(duration_usage)
  }
}

pub fn decode_usage() -> Decoder(Usage) {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "tokens" -> decode_token_usage() |> decode.map(TokenUsage)
    "duration" -> decode_duration_usage() |> decode.map(DurationUsage)
    _ -> panic as type_
  }
}

pub type TokenUsageDef {
  TokenUsageDef(
    /// Number of input tokens billed for this request.
    input_tokens: Int,
    /// Number of output tokens generated.
    output_tokens: Int,
    /// Total number of tokens used for the request.
    total_tokens: Int,
  )
}

pub fn encode_token_usage(token_usage: TokenUsageDef) -> Json {
  json.object([
    #("type", json.string("tokens")),
    #("input_tokens", json.int(token_usage.input_tokens)),
    #("output_tokens", json.int(token_usage.output_tokens)),
    #("total_tokens", json.int(token_usage.total_tokens)),
  ])
}

pub fn decode_token_usage() -> Decoder(TokenUsageDef) {
  use input_tokens <- decode.field("input_tokens", decode.int)
  use output_tokens <- decode.field("output_tokens", decode.int)
  use total_tokens <- decode.field("total_tokens", decode.int)
  decode.success(TokenUsageDef(input_tokens:, output_tokens:, total_tokens:))
}

pub type DurationUsageDef {
  DurationUsageDef(
    /// Duration of the input audio in seconds.
    seconds: Int,
  )
}

pub fn encode_duration_usage(duration_usage: DurationUsageDef) -> Json {
  json.object([
    #("type", json.string("duration")),
    #("seconds", json.int(duration_usage.seconds)),
  ])
}

pub fn decode_duration_usage() -> Decoder(DurationUsageDef) {
  use seconds <- decode.field("seconds", decode.int)
  decode.success(DurationUsageDef(seconds:))
}
