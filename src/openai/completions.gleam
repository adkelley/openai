import gleam/bit_array
import gleam/json.{type Json}
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/string

import openai/client.{type Client}
import openai/error.{type OpenAIError}
import openai/transport
import openai/types/completion.{type CompletionCreateParams}
import openai/types/role

const completions_url = "https://api.openai.com/v1/chat/completions"

const timeout = 5000

pub opaque type StreamHandler {
  StreamHandler(stream: transport.Stream)
}

pub type StreamResponse {
  StreamChunk(List(completion.CompletionChunk))
  StreamStart(StreamHandler)
  StreamEnd
}

pub fn add_message(
  messages: List(completion.Message),
  role: role.Role,
  content: String,
) {
  [
    completion.Message(
      role: role,
      content: content,
      tool_calls: None,
      refusal: None,
      annotations: [],
      audio: None,
    ),
  ]
  |> list.append(messages, _)
}

pub fn create(
  client client: Client,
  config config: CompletionCreateParams,
  messages messages: List(completion.Message),
) -> Result(completion.ChatCompletion, OpenAIError) {
  use _ <- result.try(validate_unary_config(config))
  let #(headers, body) = request_parts(config, messages)

  use resp <- result.try(client.send_text(
    client,
    transport.Post,
    completions_url,
    headers,
    body,
    None,
  ))
  use completion <- result.try(
    json.parse(resp, completion.decode_chat_completion())
    |> result.replace_error(error.BadResponse),
  )

  Ok(completion)
}

pub fn stream_create(
  client client: Client,
  config config: CompletionCreateParams,
  messages messages: List(completion.Message),
) -> Result(StreamHandler, OpenAIError) {
  use _ <- result.try(validate_streaming_config(config))
  let #(headers, body) = request_parts(config, messages)

  use stream <- result.try(client.start_stream(
    client,
    transport.Post,
    completions_url,
    [#("accept", "text/event-stream"), ..headers],
    body,
    None,
  ))

  Ok(StreamHandler(stream:))
}

pub fn stream_create_handler(
  handler: StreamHandler,
) -> Result(StreamResponse, OpenAIError) {
  stream_create_handler_loop(handler, "")
}

fn stream_create_handler_loop(
  handler: StreamHandler,
  buffer: String,
) -> Result(StreamResponse, OpenAIError) {
  let StreamHandler(stream) = handler

  case transport.receive_next(stream, timeout) {
    Ok(transport.StreamChunk(payload)) -> {
      use chunk_ <- result.try(
        payload
        |> bit_array.to_string
        |> result.replace_error(error.BadResponse),
      )
      let #(events, remaining, saw_done) =
        extract_sse_data_events(buffer <> normalize_sse_payload(chunk_))
      case events {
        [] ->
          case saw_done {
            True -> Ok(StreamEnd)
            False -> stream_create_handler_loop(handler, remaining)
          }
        _ -> {
          let res =
            list.map(events, fn(event) {
              use completion_ <- result.try(
                json.parse(event, completion.decode_completion_chunk())
                |> result.replace_error(error.BadResponse),
              )
              Ok(completion_)
            })
            |> result.values()
          Ok(StreamChunk(res))
        }
      }
    }
    Ok(transport.StreamStart) -> Ok(StreamStart(handler))
    Ok(transport.StreamEnd) -> Ok(StreamEnd)
    Ok(transport.StreamError(error)) -> Error(error)
    Error(error) -> Error(error)
  }
}

fn normalize_sse_payload(payload: String) -> String {
  payload
  |> string.replace(each: "\r\n", with: "\n")
  |> string.replace(each: "\r", with: "\n")
}

fn validate_unary_config(
  config: CompletionCreateParams,
) -> Result(Nil, OpenAIError) {
  case config.stream {
    True ->
      Error(error.InvalidRequest(
        "completions.create requires config.stream to be False",
      ))
    False -> Ok(Nil)
  }
}

fn validate_streaming_config(
  config: CompletionCreateParams,
) -> Result(Nil, OpenAIError) {
  case config.stream {
    True -> Ok(Nil)
    False ->
      Error(error.InvalidRequest(
        "completions.stream_create requires config.stream to be True",
      ))
  }
}

fn extract_sse_data_events(payload: String) -> #(List(String), String, Bool) {
  extract_sse_data_events_loop(payload, [], False)
}

fn extract_sse_data_events_loop(
  payload: String,
  events: List(String),
  saw_done: Bool,
) -> #(List(String), String, Bool) {
  case string.split_once(payload, "\n\n") {
    Ok(#(event, rest)) -> {
      let #(event_data, event_done) = extract_sse_event_data(event)
      let next_events = case event_data {
        "" -> events
        _ -> list.append(events, [event_data])
      }
      extract_sse_data_events_loop(rest, next_events, saw_done || event_done)
    }
    Error(Nil) -> #(events, payload, saw_done)
  }
}

fn extract_sse_event_data(event: String) -> #(String, Bool) {
  event
  |> string.split("\n")
  |> list.fold(#("", False), fn(acc, line) {
    let #(data, saw_done) = acc
    let trimmed = string.trim(line)
    case string.starts_with(trimmed, "data: ") {
      True -> {
        let line_data = string.drop_start(trimmed, 6) |> string.trim
        case line_data == "" {
          True -> #(data, saw_done)
          False ->
            case line_data == "[DONE]" {
              True -> #(data, True)
              False ->
                case data == "" {
                  True -> #(line_data, saw_done)
                  False -> #(data <> "\n" <> line_data, saw_done)
                }
            }
        }
      }
      False -> #(data, saw_done)
    }
  })
}

// TODO put this in an completions/decoders.gleam file
// region:    --- Json encoding
fn request_parts(
  config: CompletionCreateParams,
  messages: List(completion.Message),
) -> #(List(#(String, String)), String) {
  #([#("Content-Type", "application/json")], json_body(config, messages))
}

fn json_body(
  config: CompletionCreateParams,
  messages: List(completion.Message),
) -> String {
  let json_msg = fn(role: role.Role, content: String) {
    [
      json.object([
        #("role", role.encode_role(role)),
        #("content", json.string(content)),
      ]),
    ]
  }

  json.object([
    #("model", json.string(config.model)),
    #("temperature", json.float(config.temperature)),
    #("stream", json.bool(config.stream)),
    #(
      "messages",
      json.preprocessed_array(
        list.fold(messages, [], fn(acc: List(Json), msg: completion.Message) {
          list.append(acc, json_msg(msg.role, msg.content))
        }),
      ),
    ),
  ])
  |> json.to_string
}
// endregion: --- Json encoding
//
// TODO encode within chat/types instead of here as we do in responses code
