import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json.{type Json}
import gleam/list
import gleam/option.{None}

import chat/decoder
import chat/types.{
  type Message, type Model, type Role, Assistant, Message, Model, OtherRole,
  System, Tool, User,
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
) {
  let msg_to_json = fn(role: String, content: String) -> List(Json) {
    [
      json.object([
        #("role", json.string(role)),
        #("content", json.string(content)),
      ]),
    ]
  }
  let assert Ok(base_req) =
    request.to("https://api.openai.com/v1/chat/completions")

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

  let assert Ok(resp) = httpc.send(req)
  let assert Ok(completion) =
    json.parse(resp.body, decoder.chat_completion_decoder())
  let assert Ok(choice) = list.first(completion.choices)
  choice.message.content
}
