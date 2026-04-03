import gleam/json.{type Json}

// https://platform.openai.com/docs/guides/embeddings#embedding-models

pub type EmbeddingModels {
  TextEmbedding3Large
  TextEmbedding3Small
  TextEmbeddingAda002
  TextEmbeddingAda002V2
}

pub fn encode_embedding_model(model: EmbeddingModels) -> Json {
  embedding_model_to_string(model) |> json.string
}

pub fn embedding_model_to_string(model: EmbeddingModels) -> String {
  case model {
    TextEmbedding3Large -> "text-embedding-3-large"
    TextEmbedding3Small -> "text-embedding-3-small"
    TextEmbeddingAda002 -> "text-embedding-ada-002"
    TextEmbeddingAda002V2 -> "text-embedding-ada-002-v2"
  }
}

pub fn embedding_model_from_string(model: String) -> EmbeddingModels {
  case model {
    "text-embedding-3-large" -> TextEmbedding3Large
    "text-embedding-3-small" -> TextEmbedding3Small
    "text-embedding-ada-002" -> TextEmbeddingAda002
    "text-embedding-ada-002-v2" -> TextEmbeddingAda002V2
    _ -> panic as model
  }
}

pub type ResponseModels {
  GPT5
  GPT5Mini
  GPT5Nano
  GPT51
  GPT52
  GPT54
  GPT5Reasoning
  GPT5ReasoningMini
  GPT5Realtime
  GPT5RealtimeMini
}

pub fn encode_response_model(model: ResponseModels) -> Json {
  response_model_to_string(model)
  |> json.string
}

pub fn response_model_to_string(model: ResponseModels) -> String {
  case model {
    GPT5 -> "gpt-5"
    GPT5Mini -> "gpt-5-mini"
    GPT5Nano -> "gpt-5-nano"
    GPT51 -> "gpt-5.1"
    GPT52 -> "gpt-5.2"
    GPT54 -> "gpt-5.4"
    GPT5Reasoning -> "gpt-5-reasoning"
    GPT5ReasoningMini -> "gpt-5-reasoning-mini"
    GPT5Realtime -> "gpt-5-realtime"
    GPT5RealtimeMini -> "gpt-5-realtime-mini"
  }
}

pub fn response_model_from_string(model: String) -> ResponseModels {
  case model {
    "gpt-5" -> GPT5
    "gpt-5-mini" -> GPT5Mini
    "gpt-5-nano" -> GPT5Nano
    "gpt-5.1" -> GPT51
    "gpt-5.2" -> GPT52
    "gpt-5.4" -> GPT54
    "gpt-5-reasoning" -> GPT5Reasoning
    "gpt-5-reasoning-mini" -> GPT5ReasoningMini
    "gpt-5-realtime" -> GPT5Realtime
    "gpt-5-realtime-mini" -> GPT5RealtimeMini
    _ -> panic as model
  }
}

/// Legacy but still supported
pub type TextVision {
  GPT40
  GPT40Mini
}

pub fn encode_text_vision(m: TextVision) -> Json {
  case m {
    GPT40 -> "gpt-4o"
    GPT40Mini -> "gpt-4o-mini"
  }
  |> json.string
}

pub type ImageGeneration {
  GPTImage1
}

pub fn encode_image_generation(m: ImageGeneration) -> Json {
  case m {
    GPTImage1 -> "gpt-image-1"
  }
  |> json.string
}

pub type AudioModels {
  WhisperOne
  Gpt4oTranscribe
  Gpt4oMiniTranscribe
  Gpt4oMiniTranscribe20151215
  Gpt4oMiniDiarize
}

pub fn audio_model_to_string(model: AudioModels) -> String {
  case model {
    WhisperOne -> "whisper-1"
    Gpt4oTranscribe -> "gpt-4o-transcribe"
    Gpt4oMiniTranscribe -> "gpt-4o-mini-transcribe"
    Gpt4oMiniTranscribe20151215 -> "gpt-4o-mini-transcribe-2015-12-15"
    Gpt4oMiniDiarize -> "gpt-4o-mini-diarize"
  }
}

pub fn audio_model_from_string(model: String) -> AudioModels {
  case model {
    "whisper-1" -> WhisperOne
    "gpt-4o-transcribe" -> Gpt4oTranscribe
    "gpt-4o-mini-transcribe" -> Gpt4oMiniTranscribe
    "gpt-4o-mini-transcribe-2015-12-15" -> Gpt4oMiniTranscribe20151215
    "gpt-4o-mini-diarize" -> Gpt4oMiniDiarize
    _ -> panic as model
  }
}

pub fn encode_audio_model(model: AudioModels) -> Json {
  audio_model_to_string(model)
  |> json.string
}
