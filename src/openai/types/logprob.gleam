import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}

pub type LogProb {
  LogProb(
    /// The token.
    token: String,
    /// A list of integers representing the UTF-8 bytes of the token.
    bytes: List(Int),
    /// The log probability of this token.
    logprob: Float,
    /// The most likely tokens and their log probabilities at this position.
    top_logprobs: List(TopLogProbs),
  )
}

pub fn encode_logprob(logprob: LogProb) -> Json {
  json.object([
    #("token", json.string(logprob.token)),
    #("bytes", json.array(logprob.bytes, json.int)),
    #("logprob", json.float(logprob.logprob)),
    #("top_logprobs", json.array(logprob.top_logprobs, encode_top_logprobs)),
  ])
}

pub fn decode_logprob() -> Decoder(LogProb) {
  use token <- decode.field("token", decode.string)
  use bytes <- decode.field("bytes", decode.list(decode.int))
  use logprob <- decode.field("logprob", decode.float)
  use top_logprobs <- decode.field(
    "top_logprobs",
    decode.list(decode_top_logprob()),
  )
  decode.success(LogProb(token:, bytes:, logprob:, top_logprobs:))
}

pub type TopLogProbs {
  TopLogProbs(
    /// The token.
    token: String,
    /// A list of integers representing the UTF-8 bytes of the token.
    bytes: List(Int),
    /// The log probability of this token.
    logprob: Float,
  )
}

pub fn encode_top_logprobs(top_logprobs: TopLogProbs) -> Json {
  json.object([
    #("token", json.string(top_logprobs.token)),
    #("bytes", json.array(top_logprobs.bytes, json.int)),
    #("logprob", json.float(top_logprobs.logprob)),
  ])
}

pub fn decode_top_logprob() -> Decoder(TopLogProbs) {
  use token <- decode.field("token", decode.string)
  use bytes <- decode.field("bytes", decode.list(decode.int))
  use logprob <- decode.field("logprob", decode.float)
  decode.success(TopLogProbs(token:, bytes:, logprob:))
}
