// import gleam/dynamic/decode.{type Decoder, type Dynamic}
// import gleam/erlang/atom
// import gleam/erlang/process.{type Pid}
import gleam/bit_array
import gleam/erlang/process.{type Pid}
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/json.{type Json}
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/string

import openai/chat/decoder
import openai/chat/types.{
  type ChatCompletion, type CompletionChunk, type Config, type Message, Config,
  Message,
}
import openai/error.{type OpenaiError, BadResponse, Timeout}
import openai/shared/types as shared

const completions_url = "https://api.openai.com/v1/chat/completions"

const timeout = 5000

pub fn default_config() -> Config {
  Config(name: shared.GPT41Mini, temperature: 0.7, stream: False)
}

pub fn add_message(messages: List(Message), role: shared.Role, content: String) {
  [
    Message(
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
  client client: String,
  config config: Config,
  messages messages: List(Message),
) -> Result(ChatCompletion, OpenaiError) {
  // I think this assert is Ok
  let assert Ok(base_req) = request.to(completions_url)

  // let body = ""
  let body = body_to_json_string(config, messages)

  let req =
    base_req
    |> request.prepend_header("Content-Type", "application/json")
    |> request.prepend_header("Authorization", "Bearer " <> client)
    |> request.set_body(body)
    |> request.set_method(http.Post)

  use resp <- result.try(httpc.send(req) |> error.replace_error())
  use completion <- result.try(
    json.parse(resp.body, decoder.chat_completion_decoder())
    |> result.replace_error(BadResponse),
  )

  Ok(completion)
}

pub fn stream_create(
  client client: String,
  config config: Config,
  messages messages: List(Message),
) -> Result(List(CompletionChunk), OpenaiError) {
  // I think this assert is Ok
  let assert Ok(base_req) = request.to(completions_url)

  // ensure streaming is set to true in the model
  let model = Config(..config, stream: True)
  let body = body_to_json_string(model, messages)

  let req =
    base_req
    |> request.prepend_header("Content-Type", "application/json")
    |> request.prepend_header("Authorization", "Bearer " <> client)
    |> request.prepend_header("accept", "text/event-stream")
    |> request.set_body(body)
    |> request.set_method(http.Post)

  use request_id <- result.try(
    httpc.send_stream_request(req)
    |> result.replace_error(BadResponse),
  )

  let mapper = httpc.raw_stream_mapper()
  let selector = process.new_selector() |> httpc.select_stream_messages(mapper)

  use chunks <- result.try(loop(selector, request_id, process.self(), []))

  Ok(chunks)
}

fn loop(
  selector: process.Selector(httpc.StreamMessage),
  request_id: httpc.RequestIdentifier,
  handler_pid: Pid,
  chunks: List(CompletionChunk),
) -> Result(List(CompletionChunk), OpenaiError) {
  let response = process.selector_receive(selector, timeout)
  case response {
    Ok(httpc.StreamChunk(_request_id, payload)) -> {
      use chunk_ <- result.try(
        payload
        |> bit_array.to_string
        |> result.replace_error(BadResponse),
      )
      let chunk =
        string.split(chunk_, "data: ")
        |> list.drop(1)
        |> list.map(string.trim)
      let res =
        list.map(chunk, fn(chunk) {
          use completion <- result.try(
            json.parse(chunk, decoder.chat_completion_chunk_decoder())
            |> result.replace_error(BadResponse),
          )
          // TODO: Should this be an option?
          list.map(completion.choices, fn(choice) {
            io.print(choice.delta.content)
          })
          Ok(completion)
        })
        |> result.values()
        |> list.append(chunks)
      let _next = httpc.receive_next_stream_message(handler_pid)
      loop(selector, request_id, handler_pid, res)
    }
    Ok(httpc.StreamStart(_request_id, _headers, pid)) -> {
      let _next = httpc.receive_next_stream_message(pid)
      loop(selector, request_id, pid, chunks)
    }
    Ok(httpc.StreamEnd(_request_id, _headers)) -> {
      io.println("\n")
      Ok(chunks)
    }
    // TODO convert the HTTP Error to proper OpenaiError
    Ok(httpc.StreamError(_, _)) -> Error(BadResponse)
    Error(Nil) -> Error(Timeout)
  }
}

// region:    --- Json encoding
fn body_to_json_string(config: Config, messages: List(Message)) -> String {
  let msg_to_json = fn(role: String, content: String) {
    [
      json.object([
        #("role", json.string(role)),
        #("content", json.string(content)),
      ]),
    ]
  }

  let role_to_string = fn(role: shared.Role) {
    case role {
      shared.Assistant -> "assistant"
      shared.OtherRole(role_) -> role_
      shared.System -> "system"
      shared.Tool -> "tool"
      shared.User -> "user"
    }
  }

  json.object([
    #("model", json.string(shared.describe_model(config.name))),
    #("temperature", json.float(config.temperature)),
    #("stream", json.bool(config.stream)),
    #(
      "messages",
      json.preprocessed_array(
        list.fold(messages, [], fn(acc: List(Json), msg: Message) {
          list.append(acc, msg_to_json(role_to_string(msg.role), msg.content))
        }),
      ),
    ),
  ])
  |> json.to_string
}
// endregion: --- Json encoding
// 
// TODO Support real streaming (dependent on httpc)
// TODO break the http, parsing into separate modules?
