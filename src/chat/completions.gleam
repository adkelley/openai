import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json.{type Json}
import gleam/list
import gleam/option.{None}
import gleam/result

import chat/decoder
import chat/types.{
  type Message, type Model, type OpenaiError, type Role, Assistant, BadRequest,
  BadResponse, Message, Model, OtherRole, System, Tool, User,
}

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
) -> Result(String, OpenaiError) {
  let msg_to_json = fn(role: String, content: String) -> List(Json) {
    [
      json.object([
        #("role", json.string(role)),
        #("content", json.string(content)),
      ]),
    ]
  }
  let completions_url = "https://api.openai.com/v1/chat/completions"
  // I think this assert is Ok
  let assert Ok(base_req) = request.to(completions_url)

  let body =
    json.object([
      #("model", json.string(model.name)),
      #("temperature", json.float(model.temperature)),
      // TODO: handle streaming
      #("stream", json.bool(False)),
      #(
        "messages",
        json.preprocessed_array(
          list.fold(messages, [], fn(acc: List(Json), msg: Message) {
            case msg.role {
              Assistant ->
                list.append(acc, msg_to_json("assistant", msg.content))
              OtherRole(role) ->
                list.append(acc, msg_to_json(role, msg.content))
              System -> list.append(acc, msg_to_json("system", msg.content))
              Tool -> list.append(acc, msg_to_json("tool", msg.content))
              User -> list.append(acc, msg_to_json("user", msg.content))
            }
          }),
        ),
      ),
    ])
    |> json.to_string()

  let req =
    base_req
    |> request.prepend_header("Content-Type", "application/json")
    |> request.prepend_header("Authorization", "Bearer " <> client)
    |> request.set_body(body)
    |> request.set_method(http.Post)

  // TODO The httpc error surface area is too narrow, refine the error
  use resp <- result.try(httpc.send(req) |> result.replace_error(BadRequest))
  use completion <- result.try(
    json.parse(resp.body, decoder.chat_completion_decoder())
    |> result.replace_error(BadResponse),
  )
  use choice <- result.try(
    list.first(completion.choices) |> result.replace_error(BadResponse),
  )
  Ok(choice.message.content)
}
// TODO Support streaming
// TODO Support more refined error handling
// TODO break the http, parsing into separate modules?
