import gleam/dynamic/decode.{type Decoder}
import gleam/http/response.{type Response}
import gleam/httpc.{type HttpError}
import gleam/json
import gleam/result

/// This type represents all the reasons for why openai could fail, separate from HTTP related
pub type OpenaiError {
  /// HTTP Error (e.g, 404)
  HttpError
  /// Invalid Request - 400
  InvalidRequest(String)
  /// Bad Response: The response was invalid json or missing altogether.
  BadResponse
  /// Rate Limit
  RateLimit(String)
  /// Tokens Exceeded
  TokensExceeded(String)
  /// Unauthorized: Authentication is required.
  Authentication(String)
  /// Not Found
  NotFound(String)
  /// Internal Server Error: An error occurred on the server.
  InternalServer(String)
  /// Permission
  Permission
  /// Server Timeout
  Timeout
  /// Unknown
  Unknown
  /// File read error
  File
}

/// Replace what otherwise may a 200 status with our OpenAI error
// TODO Add support for Response(BitArray). This can be accomplished
// simply by replace_error_bitarray function.  More difficult would
// be resp: Result(Response(body), HttpError)
pub fn replace_error(
  resp: Result(Response(String), HttpError),
) -> Result(Response(String), OpenaiError) {
  let error_message_decoder = fn() -> Decoder(String) {
    use message <- decode.subfield(["error", "message"], decode.string)
    decode.success(message)
  }

  // Double check that its not an HttpError
  use resp <- result.try(resp |> result.replace_error(HttpError))

  use error_message <- result.try(case resp.status {
    status if status >= 400 && status <= 500 ->
      json.parse(resp.body, error_message_decoder())
      |> result.replace_error(BadResponse)
    _ -> Ok("")
  })

  case resp.status {
    200 -> Ok(resp)
    400 -> Error(InvalidRequest(error_message))
    429 -> Error(RateLimit(error_message))
    403 -> Error(TokensExceeded(error_message))
    401 -> Error(Authentication(error_message))
    404 -> Error(NotFound(error_message))
    500 -> Error(InternalServer(error_message))
    _ -> Error(Unknown)
  }
}
