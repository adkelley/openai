import gleam/bit_array
import gleam/float
import gleam/json
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/string
import openai/client.{type Client}
import openai/error.{type OpenAIError}
import openai/transport
import openai/types/audio/transcription.{
  type CreateTranscription, type Transcription, CreateTranscription,
}
import openai/types/audio/translation.{
  type CreateTranslation, type Translation, CreateTranslation,
}
import simplifile

const transcription_url = "https://api.openai.com/v1/audio/transcriptions"

const translation_url = "https://api.openai.com/v1/audio/translations"

const multipart_boundary = "----OpenAIAudioBoundary"

pub fn create_transcription(
  client client: Client,
  request request: CreateTranscription,
) -> Result(Transcription, OpenAIError) {
  use response_body <- result.try(send_multipart_request(
    client: client,
    url: transcription_url,
    body: build_transcription_body(request, multipart_boundary),
  ))

  json.parse(response_body, transcription.decode_transcription())
  |> result.replace_error(error.BadResponse)
}

pub fn create_translation(
  client client: Client,
  request request: CreateTranslation,
) -> Result(Translation, OpenAIError) {
  use response_body <- result.try(send_multipart_request(
    client: client,
    url: translation_url,
    body: build_translation_body(request, multipart_boundary),
  ))

  json.parse(response_body, translation.decode_translation())
  |> result.replace_error(error.BadResponse)
}

fn send_multipart_request(
  client client: Client,
  url url: String,
  body body: Result(BitArray, OpenAIError),
) -> Result(String, OpenAIError) {
  use request_body <- result.try(body)
  use response_body <- result.try(client.send_bytes(
    client,
    transport.Post,
    url,
    [#(
      "Content-Type",
      "multipart/form-data; boundary=" <> multipart_boundary,
    )],
    request_body,
    option.Some(90_000),
  ))

  case response_body {
    transport.Text(body) -> Ok(body)
    transport.Bytes(body) ->
      bit_array.to_string(body) |> result.replace_error(error.BadResponse)
  }
}

fn build_transcription_body(
  request: CreateTranscription,
  boundary: String,
) -> Result(BitArray, OpenAIError) {
  let CreateTranscription(
    file: file_path,
    model: model,
    chunking_strategy: chunking_strategy,
    include: include,
    known_speaker_names: known_speaker_names,
    known_speaker_references: known_speaker_references,
    language: language,
    prompt: prompt,
    stream: stream,
    temperature: temperature,
    timestamp_granularities: timestamp_granularities,
  ) = request

  use file_bytes <- result.try(
    simplifile.read_bits(file_path) |> result.replace_error(error.File),
  )

  let filename = extract_filename(file_path)
  let dash = "--" <> boundary <> "\r\n"

  let fields =
    form_field(dash, "model", model)
    <> case chunking_strategy {
      None -> ""
      option.Some(value) -> form_field(dash, "chunking_strategy", value)
    }
    <> case include {
      None -> ""
      option.Some(values) ->
        values
        |> list.map(fn(value) {
          form_field(
            dash,
            "include[]",
            transcription.describe_transcription_include(value),
          )
        })
        |> string.concat
    }
    <> case known_speaker_names {
      None -> ""
      option.Some(values) ->
        values
        |> list.map(fn(value) {
          form_field(dash, "known_speaker_names[]", value)
        })
        |> string.concat
    }
    <> case known_speaker_references {
      None -> ""
      option.Some(values) ->
        values
        |> list.map(fn(value) {
          form_field(dash, "known_speaker_references[]", value)
        })
        |> string.concat
    }
    <> case language {
      None -> ""
      option.Some(value) -> form_field(dash, "language", value)
    }
    <> case prompt {
      None -> ""
      option.Some(value) -> form_field(dash, "prompt", value)
    }
    <> case stream {
      None -> ""
      option.Some(value) ->
        form_field(dash, "stream", case value {
          True -> "true"
          False -> "false"
        })
    }
    <> case temperature {
      None -> ""
      option.Some(value) ->
        form_field(dash, "temperature", float.to_string(value))
    }
    <> case timestamp_granularities {
      None -> ""
      option.Some(values) ->
        values
        |> list.map(fn(value) {
          form_field(
            dash,
            "timestamp_granularities[]",
            transcription.describe_timestamp_granularity(value),
          )
        })
        |> string.concat
    }

  Ok(build_multipart_body(
    fields: fields,
    file_bytes: file_bytes,
    file_name: filename,
    boundary: boundary,
  ))
}

fn build_translation_body(
  request: CreateTranslation,
  boundary: String,
) -> Result(BitArray, OpenAIError) {
  let CreateTranslation(
    file: file_path,
    model: model,
    prompt: prompt,
    response_format: response_format,
    temperature: temperature,
  ) = request

  use file_bytes <- result.try(
    simplifile.read_bits(file_path) |> result.replace_error(error.File),
  )

  let filename = extract_filename(file_path)
  let dash = "--" <> boundary <> "\r\n"

  let fields =
    form_field(dash, "model", model)
    <> case prompt {
      None -> ""
      option.Some(value) -> form_field(dash, "prompt", value)
    }
    <> case temperature {
      None -> ""
      option.Some(value) ->
        form_field(dash, "temperature", float.to_string(value))
    }
    <> case response_format {
      None -> ""
      option.Some(value) ->
        form_field(
          dash,
          "response_format",
          translation.describe_response_formats(value),
        )
    }

  Ok(build_multipart_body(
    fields: fields,
    file_bytes: file_bytes,
    file_name: filename,
    boundary: boundary,
  ))
}

fn build_multipart_body(
  fields fields: String,
  file_bytes file_bytes: BitArray,
  file_name file_name: String,
  boundary boundary: String,
) -> BitArray {
  let file_header =
    "--"
    <> boundary
    <> "\r\n"
    <> "Content-Disposition: form-data; name=\"file\"; filename=\""
    <> file_name
    <> "\"\r\n"
    <> "Content-Type: "
    <> guess_content_type(file_name)
    <> "\r\n\r\n"

  bit_array.concat([
    bit_array.from_string(fields),
    bit_array.from_string(file_header),
    file_bytes,
    bit_array.from_string("\r\n--" <> boundary <> "--\r\n"),
  ])
}

fn form_field(dash: String, name: String, value: String) -> String {
  dash
  <> "Content-Disposition: form-data; name=\""
  <> name
  <> "\"\r\n\r\n"
  <> value
  <> "\r\n"
}

fn extract_filename(file_path: String) -> String {
  case string.split(file_path, "/") |> list.last() {
    Ok(name) -> name
    Error(Nil) -> file_path
  }
}

fn guess_content_type(filename: String) -> String {
  case string.split(filename, ".") |> list.last() {
    Ok("flac") -> "audio/flac"
    Ok("m4a") -> "audio/mp4"
    Ok("mp3") -> "audio/mpeg"
    Ok("mp4") -> "audio/mp4"
    Ok("mpeg") -> "audio/mpeg"
    Ok("mpga") -> "audio/mpeg"
    Ok("ogg") -> "audio/ogg"
    Ok("wav") -> "audio/wav"
    Ok("webm") -> "audio/webm"
    _ -> "application/octet-stream"
  }
}
