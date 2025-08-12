import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/list

import chat/decoder
import chat/types.{type Model, Model}

pub fn new() -> Model {
  Model(name: "gpt-4.1", temperature: 0.7, stream: False)
}

pub fn create(
  client client: String,
  model model: Model,
  messages messages: String,
) {
  let assert Ok(base_req) =
    request.to("https://api.openai.com/v1/chat/completions")

  let body =
    json.object([
      #("model", json.string(model.name)),
      #("temperature", json.float(model.temperature)),
      // TODO: handle streaming
      #("stream", json.bool(False)),
      // TODO: handle multiple messages
      #(
        "messages",
        json.preprocessed_array([
          json.object([
            #("role", json.string("user")),
            #("content", json.string(messages)),
          ]),
        ]),
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
