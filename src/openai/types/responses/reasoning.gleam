import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None}
import openai/types/helpers

pub type Status {
  InProgress
  Completed
  Incomplete
}

pub fn encode_status(status: Status) -> Json {
  case status {
    InProgress -> "in_progress"
    Completed -> "completed"
    Incomplete -> "incomplete"
  }
  |> json.string
}

fn decode_status() -> Decoder(Status) {
  decode.string
  |> decode.map(fn(status) {
    case status {
      "in_progress" -> InProgress
      "completed" -> Completed
      "incomplete" -> Incomplete
      _ -> panic as status
    }
  })
}

pub type ReasoningEffort {
  Low
  Medium
  High
  XHigh
  Minimal
  Nil
}

fn encode_reasoning_effort(reasoning_effort: ReasoningEffort) -> Json {
  case reasoning_effort {
    Low -> json.string("low")
    Medium -> json.string("medium")
    High -> json.string("high")
    XHigh -> json.string("xhigh")
    Minimal -> json.string("minimal")
    Nil -> json.string("none")
  }
}

fn decode_reasoning_effort() -> Decoder(ReasoningEffort) {
  decode.string
  |> decode.map(fn(reasoning_effort) {
    case reasoning_effort {
      "low" -> Low
      "medium" -> Medium
      "high" -> High
      "xhigh" -> XHigh
      "minimal" -> Minimal
      "none" -> Nil
      _ -> panic as reasoning_effort
    }
  })
}

pub type ReasoningSummary {
  Auto
  Concise
  Detailed
}

fn encode_reasoning_summary(reasoning_summary: ReasoningSummary) -> Json {
  case reasoning_summary {
    Auto -> json.string("auto")
    Concise -> json.string("concise")
    Detailed -> json.string("detailed")
  }
}

pub fn decode_reasoning_summary() -> Decoder(ReasoningSummary) {
  decode.string
  |> decode.map(fn(reasoning_summary) {
    case reasoning_summary {
      "auto" -> Auto
      "concise" -> Concise
      "detailed" -> Detailed
      _ -> panic as reasoning_summary
    }
  })
}

pub type ReasoningDef {
  ReasoningDef(
    /// Constrains effort on reasoning for reasoning models.
    effort: Option(ReasoningEffort),
    /// A summary of the reasoning performed by the model.
    summary: Option(ReasoningSummary),
  )
}

pub fn encode_reasoning(reasoning: ReasoningDef) -> Json {
  []
  |> helpers.encode_option("effort", reasoning.effort, encode_reasoning_effort)
  |> helpers.encode_option(
    "summary",
    reasoning.summary,
    encode_reasoning_summary,
  )
  |> json.object
}

pub fn decode_reasoning() -> Decoder(ReasoningDef) {
  use effort <- decode.optional_field(
    "effort",
    None,
    decode.optional(decode_reasoning_effort()),
  )
  use summary <- decode.optional_field(
    "summary",
    None,
    decode.optional(decode_reasoning_summary()),
  )
  decode.success(ReasoningDef(effort:, summary:))
}

pub type SummaryText {
  SummaryText(
    // type: "summary_text"
    text: String,
  )
}

fn encode_summary_text(summary: SummaryText) -> Json {
  json.object([
    #("type", json.string("summary_text")),
    #("text", json.string(summary.text)),
  ])
}

pub type ReasoningText {
  ReasoningText(
    // type: "reasoning_text"
    text: String,
  )
}

fn encode_reasoning_text(reasoning: ReasoningText) -> Json {
  json.object([
    #("type", json.string("reasoning_text")),
    #("text", json.string(reasoning.text)),
  ])
}

pub type ReasoningOutputDef {
  ReasoningOutputDef(
    /// The unique identifier of the reasoning content.
    id: String,
    /// Reasoning summary content.
    summary: List(SummaryText),
    // type: "reasoning"
    /// Reasoning text content.
    content: Option(List(ReasoningText)),
    /// Encrypted reasoning content for continued conversations.
    encrypted_content: Option(String),
    /// The status of the reasoning item.
    status: Option(Status),
  )
}

pub fn encode_reasoning_output(reasoning_output: ReasoningOutputDef) -> Json {
  [
    #("type", json.string("reasoning")),
    #("id", json.string(reasoning_output.id)),
    #("summary", json.array(reasoning_output.summary, encode_summary_text)),
  ]
  |> helpers.encode_option_list(
    "content",
    reasoning_output.content,
    encode_reasoning_text,
  )
  |> helpers.encode_option(
    "encrypted_content",
    reasoning_output.encrypted_content,
    json.string,
  )
  |> json.object
}

pub fn decode_reasoning_output() -> Decoder(ReasoningOutputDef) {
  let decode_summary = fn() {
    use type_ <- decode.field("type", decode.string)
    assert type_ == "summary_text"
    use text <- decode.field("text", decode.string)
    decode.success(SummaryText(text))
  }

  let decode_content = fn() {
    use type_ <- decode.field("type", decode.string)
    assert type_ == "reasoning_text"
    use text <- decode.field("text", decode.string)
    decode.success(ReasoningText(text))
  }
  use id <- decode.field("id", decode.string)
  use summary <- decode.field("summary", decode.list(decode_summary()))
  use content <- decode.optional_field(
    "content",
    None,
    decode.optional(decode.list(decode_content())),
  )
  use encrypted_content <- decode.optional_field(
    "encrypted_content",
    None,
    decode.optional(decode.string),
  )
  use status <- decode.optional_field(
    "status",
    None,
    decode.optional(decode_status()),
  )
  decode.success(ReasoningOutputDef(
    id:,
    summary:,
    content:,
    encrypted_content:,
    status:,
  ))
}
