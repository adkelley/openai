import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/list
import gleam/string

import chat/decoder

pub fn create(
  client client: String,
  model model: String,
  messages messages: String,
) {
  let assert Ok(base_req) =
    request.to("https://api.openai.com/v1/chat/completions")

  let model =
    json.object([#("model", json.string(model))])
    |> json.to_string()
    |> string.replace(each: "}", with: ",")

  // TODO: handle multiple messages
  let messages =
    json.object([
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
    |> json.to_string
    |> string.drop_start(up_to: 1)

  let body_string = model <> messages

  let req =
    base_req
    |> request.prepend_header("Content-Type", "application/json")
    |> request.prepend_header("Authorization", "Bearer " <> client)
    |> request.set_body(body_string)
    |> request.set_method(http.Post)

  let assert Ok(resp) = httpc.send(req)
  let assert Ok(completion) =
    json.parse(resp.body, decoder.chat_completion_decoder())
  let assert Ok(choice) = list.first(completion.choices)
  choice.message.content
}
