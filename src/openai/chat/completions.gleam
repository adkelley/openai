import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json.{type Json}
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/string

import openai/chat/decoder
import openai/chat/types.{
  type ChatCompletion, type Message, type Model, type Role, Assistant, Message,
  Model, OtherRole, System, Tool, User,
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

pub fn create_streaming(
  client client: String,
  model model: Model,
  messages messages: List(Message),
  // ) -> Result(ChatCompletion, OpenaiError) {
) {
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

  // TODO Report OpenAI API errors to user
  use resp <- result.try(httpc.send(req) |> error.replace_error())
  // http streaming is not supported by httpc. See Issue (https://github.com/gleam-lang/httpc/issues/31).
  // This is a work around until http streaming is supported
  let chunks =
    string.split(resp.body, "data: ")
    |> list.drop(1)
    |> list.map(string.trim)
  let chunks = list.take(chunks, list.length(chunks) - 1)
  let res =
    list.map(chunks, fn(chunk) {
      use completion <- result.try(
        json.parse(chunk, decoder.chat_completion_chunk_decoder())
        |> result.replace_error(BadResponse),
      )
      Ok(completion)
    })
    |> result.values()
  Ok(res)
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
    // TODO: handle streaming
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
