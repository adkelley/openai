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

import openai/completions/decoders
import openai/completions/types as completions
import openai/error
import openai/types as shared

const completions_url = "https://api.openai.com/v1/chat/completions"

const timeout = 5000

pub fn default_config() -> completions.Config {
  completions.Config(name: shared.GPT41Mini, temperature: 0.7, stream: False)
}

pub fn add_message(
  messages: List(completions.Message),
  role: shared.Role,
  content: String,
) {
  [
    completions.Message(
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
  config config: completions.Config,
  messages messages: List(completions.Message),
) -> Result(completions.ChatCompletion, error.OpenaiError) {
  // I think this assert is Ok
  let assert Ok(base_req) = request.to(completions_url)

  // let body = ""
  let body = json_body(config, messages)

  let req =
    base_req
    |> request.prepend_header("Content-Type", "application/json")
    |> request.prepend_header("Authorization", "Bearer " <> client)
    |> request.set_body(body)
    |> request.set_method(http.Post)

  use resp <- result.try(httpc.send(req) |> error.replace_error())
  use completion <- result.try(
    json.parse(resp.body, decoders.chat_completion_decoder())
    |> result.replace_error(error.BadResponse),
  )

  Ok(completion)
}

pub fn stream_create(
  client client: String,
  config config: completions.Config,
  messages messages: List(completions.Message),
) -> Result(List(completions.CompletionChunk), error.OpenaiError) {
  // I think this assert is Ok
  let assert Ok(base_req) = request.to(completions_url)

  // ensure streaming is set to true in the model
  let model = completions.Config(..config, stream: True)
  let body = json_body(model, messages)

  let req =
    base_req
    |> request.prepend_header("Content-Type", "application/json")
    |> request.prepend_header("Authorization", "Bearer " <> client)
    |> request.prepend_header("accept", "text/event-stream")
    |> request.set_body(body)
    |> request.set_method(http.Post)

  use request_id <- result.try(
    httpc.send_stream_request(req)
    |> result.replace_error(error.BadResponse),
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
  chunks: List(completions.CompletionChunk),
) -> Result(List(completions.CompletionChunk), error.OpenaiError) {
  let response = process.selector_receive(selector, timeout)
  case response {
    Ok(httpc.StreamChunk(_request_id, payload)) -> {
      use chunk_ <- result.try(
        payload
        |> bit_array.to_string
        |> result.replace_error(error.BadResponse),
      )
      let chunk =
        string.split(chunk_, "data: ")
        |> list.drop(1)
        |> list.map(string.trim)
      let res =
        list.map(chunk, fn(chunk) {
          use completion <- result.try(
            json.parse(chunk, decoders.chat_completion_chunk_decoder())
            |> result.replace_error(error.BadResponse),
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
    Ok(httpc.StreamError(_, _)) -> Error(error.BadResponse)
    Error(Nil) -> Error(error.Timeout)
  }
}

// region:    --- Json encoding
fn json_body(
  config: completions.Config,
  messages: List(completions.Message),
) -> String {
  let json_msg = fn(role: shared.Role, content: String) {
    [
      json.object([
        #("role", shared.role_encoder(role)),
        #("content", json.string(content)),
      ]),
    ]
  }

  json.object([
    #("model", shared.model_encoder(config.name)),
    #("temperature", json.float(config.temperature)),
    #("stream", json.bool(config.stream)),
    #(
      "messages",
      json.preprocessed_array(
        list.fold(messages, [], fn(acc: List(Json), msg: completions.Message) {
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
