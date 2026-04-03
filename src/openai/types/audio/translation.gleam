import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import openai/types/helpers

pub type CreateTranslation {
  CreateTranslation(
    file: String,
    model: String,
    prompt: Option(String),
    response_format: Option(ResponseFormats),
    temperature: Option(Float),
  )
}

pub fn new() -> CreateTranslation {
  CreateTranslation(
    file: "",
    model: "whisper-1",
    prompt: None,
    response_format: None,
    temperature: None,
  )
}

pub fn with_file(
  translation: CreateTranslation,
  file_path: String,
) -> CreateTranslation {
  CreateTranslation(..translation, file: file_path)
}

pub fn with_model(
  translation: CreateTranslation,
  model_name: String,
) -> CreateTranslation {
  CreateTranslation(..translation, model: model_name)
}

pub fn with_prompt(
  translation: CreateTranslation,
  prompt_text: String,
) -> CreateTranslation {
  CreateTranslation(..translation, prompt: Some(prompt_text))
}

pub fn with_response_format(
  translation: CreateTranslation,
  response_format: ResponseFormats,
) -> CreateTranslation {
  CreateTranslation(..translation, response_format: Some(response_format))
}

pub fn with_temperature(
  translation: CreateTranslation,
  temperature_value: Float,
) -> CreateTranslation {
  CreateTranslation(..translation, temperature: Some(temperature_value))
}

pub fn encode_translation(create_translation: CreateTranslation) -> Json {
  [
    #("file", json.string(create_translation.file)),
    #("model", json.string(create_translation.model)),
  ]
  |> helpers.encode_option("prompt", create_translation.prompt, json.string)
  |> helpers.encode_option(
    "response_format",
    create_translation.response_format,
    encode_response_formats,
  )
  |> helpers.encode_option(
    "temperature",
    create_translation.temperature,
    json.float,
  )
  |> json.object
}

pub type ResponseFormats {
  Json
  Text
  SRT
  VerboseJson
  VTT
}

fn encode_response_formats(response_format: ResponseFormats) -> Json {
  describe_response_formats(response_format)
  |> json.string
}

pub fn describe_response_formats(response_formats: ResponseFormats) -> String {
  case response_formats {
    Json -> "json"
    Text -> "text"
    SRT -> "srt"
    VerboseJson -> "verbose_json"
    VTT -> "vtt"
  }
}

pub type Translation {
  Translation(text: String)
}

pub fn decode_translation() -> Decoder(Translation) {
  use text <- decode.field("text", decode.string)
  decode.success(Translation(text:))
}
