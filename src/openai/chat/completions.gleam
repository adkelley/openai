// import gleam/dynamic/decode.{type Decoder, type Dynamic}
// import gleam/erlang/atom
// import gleam/erlang/process.{type Pid}
import gleam/bit_array
import gleam/erlang/atom
import gleam/erlang/process.{type Pid}
import gleam/erlang/reference.{type Reference}
import gleam/http
import gleam/http/request
import gleam/httpc.{StreamSelfOnce}
import gleam/io
import gleam/json.{type Json}
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/string

import openai/chat/decoder
import openai/chat/types.{
  type ChatCompletion, type CompletionChunk, type Message, type Model, type Role,
  Assistant, Message, Model, OtherRole, System, Tool, User,
}
import openai/error.{type OpenaiError, BadResponse}

const completions_url = "https://api.openai.com/v1/chat/completions"

pub fn default_model() -> Model {
  Model(name: "gpt-4.1-mini", temperature: 0.7, stream: False)
}

pub fn add_message(messages: List(Message), role: Role, content: String) {
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
  model model: Model,
  messages messages: List(Message),
) -> Result(ChatCompletion, OpenaiError) {
  // I think this assert is Ok
  let assert Ok(base_req) = request.to(completions_url)

  // let body = ""
  let body = body_to_json_string(model, messages)

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

pub fn async_create(
  client client: String,
  model model: Model,
  messages messages: List(Message),
) -> Result(List(CompletionChunk), OpenaiError) {
  // I think this assert is Ok
  let assert Ok(base_req) = request.to(completions_url)

  // ensure streaming is set to true in the model
  let model = Model(..model, stream: True)
  let body = body_to_json_string(model, messages)

  let req =
    base_req
    |> request.prepend_header("Content-Type", "application/json")
    |> request.prepend_header("Authorization", "Bearer " <> client)
    |> request.prepend_header("accept", "text/event-stream")
    |> request.set_body(body)
    |> request.set_method(http.Post)

  let config = httpc.configure() |> httpc.async_stream(StreamSelfOnce)

  // TODO return a proper error response
  use request_id <- result.try(
    httpc.async_dispatch(config, req)
    |> result.replace_error(BadResponse),
  )
  use chunks <- result.try(loop(request_id, process.self(), []))
  Ok(chunks)
}

fn loop(
  request_id: Reference,
  handler_pid: Pid,
  chunks: List(CompletionChunk),
) -> Result(List(CompletionChunk), OpenaiError) {
  use payload_ <- result.try(
    httpc.async_receive(request_id, 10_000) |> result.replace_error(BadResponse),
  )
  let #(stream_state_, payload) = payload_
  let stream_state = atom.to_string(stream_state_)
  case stream_state {
    "stream_start" -> {
      let #(_headers, pid) = httpc.dynamic_to_headers_pid(payload)
      use _next <- result.try(
        httpc.async_stream_next(pid) |> result.replace_error(BadResponse),
      )
      loop(request_id, pid, chunks)
    }
    "stream" -> {
      use chunk_ <- result.try(
        httpc.dynamic_to_bit_array(payload)
        |> bit_array.to_string
        |> result.replace_error(BadResponse),
      )
      // echo "stream"
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
      use _next <- result.try(
        httpc.async_stream_next(handler_pid)
        |> result.replace_error(BadResponse),
      )
      loop(request_id, handler_pid, res)
    }
    "stream_end" -> {
      // echo "stream_end"
      io.println("")
      list.reverse(chunks) |> Ok
    }
    _ -> {
      Error(BadResponse)
    }
  }
}

// region:    --- Json encoding
fn body_to_json_string(model: Model, messages: List(Message)) -> String {
  let msg_to_json = fn(role: String, content: String) {
    [
      json.object([
        #("role", json.string(role)),
        #("content", json.string(content)),
      ]),
    ]
  }

  let role_to_string = fn(role: Role) {
    case role {
      Assistant -> "assistant"
      OtherRole(role_) -> role_
      System -> "system"
      Tool -> "tool"
      User -> "user"
    }
  }

  json.object([
    #("model", json.string(model.name)),
    #("temperature", json.float(model.temperature)),
    #("stream", json.bool(model.stream)),
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
