import gleam/bit_array
import gleam/erlang/process
import gleam/http
import gleam/http/request
import gleam/httpc
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import openai/error.{type OpenAIError}

pub type Body {
  Text(String)
  Bytes(BitArray)
}

pub type Method {
  Get
  Post
  Delete
}

pub type TransportRequest {
  TransportRequest(
    method: Method,
    url: String,
    headers: List(#(String, String)),
    body: Body,
    timeout_ms: Option(Int),
  )
}

pub type TransportResponse {
  TransportResponse(
    status: Int,
    headers: List(#(String, String)),
    body: Body,
  )
}

pub type StreamMessage {
  StreamStart
  StreamChunk(BitArray)
  StreamEnd
  StreamError(OpenAIError)
}

pub opaque type Stream {
  Stream(receive_next: fn(Int) -> Result(StreamMessage, OpenAIError))
}

pub opaque type Transport {
  Transport(
    send: fn(TransportRequest) -> Result(TransportResponse, OpenAIError),
    start_stream: fn(TransportRequest) -> Result(Stream, OpenAIError),
  )
}

pub fn new_transport(
  send: fn(TransportRequest) -> Result(TransportResponse, OpenAIError),
) -> Transport {
  Transport(send:, start_stream: unsupported_streaming)
}

pub fn new_transport_with_stream(
  send: fn(TransportRequest) -> Result(TransportResponse, OpenAIError),
  start_stream: fn(TransportRequest) -> Result(Stream, OpenAIError),
) -> Transport {
  Transport(send:, start_stream:)
}

pub fn new_stream(
  receive_next: fn(Int) -> Result(StreamMessage, OpenAIError),
) -> Stream {
  Stream(receive_next:)
}

pub fn send(
  transport: Transport,
  transport_request: TransportRequest,
) -> Result(TransportResponse, OpenAIError) {
  let Transport(send, _) = transport
  send(transport_request)
}

pub fn start_stream(
  transport: Transport,
  transport_request: TransportRequest,
) -> Result(Stream, OpenAIError) {
  let Transport(_, start_stream) = transport
  start_stream(transport_request)
}

pub fn receive_next(
  stream: Stream,
  timeout_ms: Int,
) -> Result(StreamMessage, OpenAIError) {
  let Stream(receive_next) = stream
  receive_next(timeout_ms)
}

pub fn httpc_transport() -> Transport {
  new_transport_with_stream(httpc_send, httpc_start_stream)
}

fn httpc_send(
  transport_request: TransportRequest,
) -> Result(TransportResponse, OpenAIError) {
  let TransportRequest(method, url, headers, body, timeout_ms) = transport_request
  case body {
    Text(body) -> send_text_request(method, url, headers, body, timeout_ms)
    Bytes(body) -> send_bits_request(method, url, headers, body, timeout_ms)
  }
}

fn send_text_request(
  method: Method,
  url: String,
  headers: List(#(String, String)),
  body: String,
  timeout_ms: Option(Int),
) -> Result(TransportResponse, OpenAIError) {
  let assert Ok(base_request) = request.to(url)

  let req =
    base_request
    |> apply_headers(headers)
    |> request.set_method(to_http_method(method))
    |> request.set_body(body)

  use response <- result.try(
    http_client(timeout_ms)
    |> httpc.dispatch(req)
    |> result.replace_error(error.HttpError),
  )

  Ok(TransportResponse(status: response.status, headers: [], body: Text(response.body)))
}

fn send_bits_request(
  method: Method,
  url: String,
  headers: List(#(String, String)),
  body: BitArray,
  timeout_ms: Option(Int),
) -> Result(TransportResponse, OpenAIError) {
  let assert Ok(base_request) = request.to(url)

  let req =
    base_request
    |> request.map(bit_array.from_string)
    |> apply_headers(headers)
    |> request.set_method(to_http_method(method))
    |> request.set_body(body)

  use response <- result.try(
    http_client(timeout_ms)
    |> httpc.dispatch_bits(req)
    |> result.replace_error(error.HttpError),
  )

  Ok(TransportResponse(status: response.status, headers: [], body: Bytes(response.body)))
}

fn httpc_start_stream(
  transport_request: TransportRequest,
) -> Result(Stream, OpenAIError) {
  let stream_subject = process.new_subject()
  let setup_subject = process.new_subject()

  let _worker =
    process.spawn(fn() {
      httpc_stream_worker(transport_request, stream_subject, setup_subject)
    })

  use _ <- result.try(
    process.receive(setup_subject, within: 5_000)
    |> result.replace_error(error.Timeout),
  )

  Ok(new_stream(fn(timeout_ms) {
    process.receive(stream_subject, within: timeout_ms)
    |> result.replace_error(error.Timeout)
  }))
}

fn httpc_stream_worker(
  transport_request: TransportRequest,
  stream_subject: process.Subject(StreamMessage),
  setup_subject: process.Subject(Result(Nil, OpenAIError)),
) -> Nil {
  case httpc_dispatch_stream_request(transport_request) {
    Ok(request_id) -> {
      process.send(setup_subject, Ok(Nil))

      let selector =
        process.new_selector()
        |> httpc.select_stream_messages(httpc.raw_stream_mapper())

      httpc_stream_loop(selector, request_id, stream_subject, None)
    }
    Error(error) -> {
      process.send(setup_subject, Error(error))
      Nil
    }
  }
}

fn httpc_dispatch_stream_request(
  transport_request: TransportRequest,
) -> Result(httpc.RequestIdentifier, OpenAIError) {
  let TransportRequest(method, url, headers, body, timeout_ms) = transport_request
  let assert Ok(base_request) = request.to(url)

  case body {
    Text(body) -> {
      let req =
        base_request
        |> apply_headers(headers)
        |> request.set_method(to_http_method(method))
        |> request.set_body(body)

      http_client(timeout_ms)
      |> httpc.dispatch_stream_request(req)
      |> result.replace_error(error.BadResponse)
    }
    Bytes(body) -> {
      let req =
        base_request
        |> request.map(bit_array.from_string)
        |> apply_headers(headers)
        |> request.set_method(to_http_method(method))
        |> request.set_body(body)

      http_client(timeout_ms)
      |> httpc.dispatch_stream_bits(req)
      |> result.replace_error(error.BadResponse)
    }
  }
}

fn httpc_stream_loop(
  selector: process.Selector(httpc.StreamMessage),
  request_id: httpc.RequestIdentifier,
  stream_subject: process.Subject(StreamMessage),
  stream_pid: Option(process.Pid),
) -> Nil {
  case process.selector_receive_forever(selector) {
    httpc.StreamStart(request_id_, _headers, pid) -> {
      case request_id_ == request_id {
        True -> {
          process.send(stream_subject, StreamStart)
          let _ = httpc.receive_next_stream_message(pid)
          httpc_stream_loop(selector, request_id, stream_subject, Some(pid))
        }
        False -> httpc_stream_loop(selector, request_id, stream_subject, stream_pid)
      }
    }
    httpc.StreamChunk(request_id_, payload) -> {
      case request_id_ == request_id {
        True -> {
          process.send(stream_subject, StreamChunk(payload))
          case stream_pid {
            Some(pid) -> {
              let _ = httpc.receive_next_stream_message(pid)
              httpc_stream_loop(selector, request_id, stream_subject, Some(pid))
            }
            None -> {
              process.send(stream_subject, StreamError(error.BadResponse))
              Nil
            }
          }
        }
        False -> httpc_stream_loop(selector, request_id, stream_subject, stream_pid)
      }
    }
    httpc.StreamEnd(request_id_, _headers) -> {
      case request_id_ == request_id {
        True -> process.send(stream_subject, StreamEnd)
        False -> httpc_stream_loop(selector, request_id, stream_subject, stream_pid)
      }
    }
    httpc.StreamError(request_id_, stream_error) -> {
      case request_id_ == request_id {
        True -> process.send(stream_subject, StreamError(map_stream_error(stream_error)))
        False -> httpc_stream_loop(selector, request_id, stream_subject, stream_pid)
      }
    }
  }
}

fn apply_headers(
  req: request.Request(body),
  headers: List(#(String, String)),
) -> request.Request(body) {
  list.fold(headers, req, fn(req, header) {
    let #(name, value) = header
    request.prepend_header(req, name, value)
  })
}

fn http_client(timeout_ms: Option(Int)) {
  case timeout_ms {
    Some(timeout_ms) -> httpc.configure() |> httpc.timeout(timeout_ms)
    None -> httpc.configure()
  }
}

fn to_http_method(method: Method) -> http.Method {
  case method {
    Get -> http.Get
    Post -> http.Post
    Delete -> http.Delete
  }
}

fn unsupported_streaming(_transport_request: TransportRequest) -> Result(Stream, OpenAIError) {
  Error(error.Unknown)
}

fn map_stream_error(stream_error: httpc.HttpError) -> OpenAIError {
  case stream_error {
    httpc.ResponseTimeout -> error.Timeout
    _ -> error.HttpError
  }
}
