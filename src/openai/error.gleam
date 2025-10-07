import gleam/http/response.{type Response, Response}
import gleam/httpc.{type HttpError}
import gleam/result

/// This type represents all the reasons for why openai could fail, separate from HTTP related
pub type OpenaiError {
  /// HTTP Error (e.g, 404)
  HttpError
  /// Invalid Request - 400
  InvalidRequest
  /// Bad Response: The response was invalid json or missing altogether.
  BadResponse
  /// Rate Limit
  RateLimit
  /// Tokens Exceeded
  TokensExceeded
  /// Unauthorized: Authentication is required.
  Authentication
  /// Not Found
  NotFound
  /// Internal Server Error: An error occurred on the server.
  InternalServer
  /// Permission
  Permission
  /// Server Timeout
  Timeout
  /// Unknown
  Unknown
}

/// Replace what otherwise may a 200 status with our OpenAI error
pub fn replace_error(
  resp: Result(Response(body), HttpError),
) -> Result(Response(body), OpenaiError) {
  use resp <- result.try(resp |> result.replace_error(HttpError))
  let Response(status, _, _) = resp
  case status {
    200 -> Ok(resp)
    400 -> Error(InvalidRequest)
    429 -> Error(RateLimit)
    403 -> Error(TokensExceeded)
    401 -> Error(Authentication)
    404 -> Error(NotFound)
    500 -> Error(InternalServer)
    _ -> Error(Unknown)
  }
}
