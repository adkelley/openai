import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/io
import gleam/json.{type Json}
import gleam/list
import gleam/option.{None}
import gleam/result
import gleam/string

import chat/decoder
import chat/types.{
  type Message, type Model, type OpenaiError, type Role, Assistant, BadRequest,
  BadResponse, Message, Model, OtherRole, System, Tool, User,
}

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
) -> Result(String, OpenaiError) {
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
  use resp <- result.try(httpc.send(req) |> result.replace_error(BadRequest))
  case model.stream {
    False -> {
      use completion <- result.try(
        json.parse(resp.body, decoder.chat_completion_decoder())
        |> result.replace_error(BadResponse),
      )
      use choice <- result.try(
        list.first(completion.choices) |> result.replace_error(BadResponse),
      )
      Ok(choice.message.content)
    }
    // http streaming is not supported by httpc. See Issue (https://github.com/gleam-lang/httpc/issues/31).
    // This is a work around that is essentially the same result as No streaming
    True -> {
      let chunks =
        string.split(resp.body, "data: ")
        |> list.drop(1)
        |> list.map(string.trim)
      let chunks = list.take(chunks, list.length(chunks) - 1)
      // |> echo
      let _res =
        list.map(chunks, fn(chunk) {
          use completion <- result.try(
            json.parse(chunk, decoder.chat_completion_chunk_decoder())
            // |> echo
            |> result.replace_error(BadResponse),
          )
          use choice <- result.try(
            list.first(completion.choices) |> result.replace_error(BadResponse),
          )
          io.print(choice.delta.content)
          Ok(choice.delta.content)
        })
      io.println("\n")
      // |> echo
      Ok("streamed")
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

  json.object([
    #("model", json.string(model.name)),
    #("temperature", json.float(model.temperature)),
    // TODO: handle streaming
    #("stream", json.bool(model.stream)),
    #(
      "messages",
      json.preprocessed_array(
        list.fold(messages, [], fn(acc: List(Json), msg: Message) {
          case msg.role {
            Assistant -> list.append(acc, msg_to_json("assistant", msg.content))
            OtherRole(role) -> list.append(acc, msg_to_json(role, msg.content))
            System -> list.append(acc, msg_to_json("system", msg.content))
            Tool -> list.append(acc, msg_to_json("tool", msg.content))
            User -> list.append(acc, msg_to_json("user", msg.content))
          }
        }),
      ),
    ),
  ])
  |> json.to_string
}
// endregion: --- Json encoding
// region:    --- Error handling
// Ok(Response(400, [#("connection", "close"), #("date", "Thu, 28 Aug 2025 20:13:21 GMT"), #("server", "cloudflare"), #("vary", "Origin"), #("content-length", "443"), #("content-type", "application/json; charset=utf-8"), #("x-request-id", "req_336b1011bc06484a8668624e27c350ba"), #("cf-cache-status", "DYNAMIC"), #("set-cookie", "__cf_bm=IBj_19KJnkZ5Su9S9AIuouZgFvOwCpUMT59kX8MtULc-1756412001-1.0.1.1-CiQ_F_bYYkFXyZ0Qrpaxp7G4BJwUrZvaMVNNQ1Sr5uYttZS0Wjsi2LihVCO129ylj8i1dbK06ildqHlUkFdW8X6Q6I6CCKGN9UIvsMDjYR4; path=/; expires=Thu, 28-Aug-25 20:43:21 GMT; domain=.api.openai.com; HttpOnly; Secure; SameSite=None"), #("strict-transport-security", "max-age=31536000; includeSubDomains; preload"), #("x-content-type-options", "nosniff"), #("set-cookie", "_cfuvid=9WhSmPE8L5WUcRiqrNCG9pVEaNiXbgK0EzgWsR3f_mo-1756412001421-0.0.1.1-604800000; path=/; domain=.api.openai.com; HttpOnly; Secure; SameSite=None"), #("cf-ray", "976677fbd983cf82-SJC"), #("alt-svc", "h3=\":443\"; ma=86400")], "{\n    \"error\": {\n        \"message\": \"We could not parse the JSON body of your request. (HINT: This likely means you aren't using your HTTP library correctly. The OpenAI API expects a JSON payload, but what was sent was not valid JSON. If you have trouble figuring out how to fix this, please contact us through our help center at help.openai.com.)\",\n        \"type\": \"invalid_request_error\",\n        \"param\": null,\n        \"code\": null\n    }\n}\n"))
// endregion: --- Error handling
// 
// TODO Support streaming
// TODO Support more refined error handling
// TODO break the http, parsing into separate modules?
