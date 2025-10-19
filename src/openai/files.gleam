/// Helpers for interacting with the OpenAI Files API, including upload, list,
/// delete, and retrieval utilities.
import gleam/bit_array
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response as http_response
import gleam/httpc
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string

import openai/error
import simplifile

// Base endpoint for all file-related requests sent to OpenAI.
const files_url = "https://api.openai.com/v1/files"

/// Describes the payload sent when uploading a new file to the API.
pub type File {
  File(
    /// The File object (not file name) to be uploaded.
    file: FileInfo,
    /// The intended purpose of the uploaded file. One of:
    /// - assistants: Used in the Assistants API
    /// - batch: Used in the Batch API
    /// - fine-tune: Used for fine-tuning
    /// - vision: Images used for vision fine-tuning
    /// - user_data: Flexible file type for any purpose
    /// - evals: Used for eval data sets
    purpose: FilePurpose,
    /// The expiration policy for a file. By default, files with purpose=batch
    /// expire after 30 days and all other files are persisted until they are
    /// manually deleted.
    expires_after: Option(ExpiresAfter),
  )
}

/// Builder struct for configuring `list` calls with pagination or filters.
pub opaque type FileListParams {
  FileListParams(
    /// A cursor for use in pagination. after is an object ID that defines your place
    /// in the list. For instance, if you make a list request and receive 100 objects, ending
    /// with obj_foo, your subsequent call can include after=obj_foo in order to fetch the
    /// next page of the list.
    after: Option(String),
    /// A limit on the number of objects to be returned. Limit can range between 1 and 10,000,
    /// and the default is 10,000.
    limit: Option(Int),
    /// Sort order by the created_at timestamp of the objects. asc for ascending order and
    /// desc for descending order.
    order: Option(String),
    /// Only return files with the given purpose.
    purpose: Option(String),
  )
}

/// Sets the maximum number of files to request, clamping to the API limits.
pub fn file_list_limit(config: FileListParams, limit: Int) -> FileListParams {
  let limit_ = case limit {
    x if x > 0 && x <= 10_000 -> x
    _ -> 10_000
  }
  FileListParams(..config, limit: option.Some(limit_))
}

/// Restricts the list request to files with the given purpose.
pub fn file_list_purpose(
  config: FileListParams,
  purpose: FilePurpose,
) -> FileListParams {
  FileListParams(..config, purpose: option.Some(describe_file_purpose(purpose)))
}

/// Controls whether results are returned ascending or descending by creation time.
pub fn file_list_order(config: FileListParams, order: String) -> FileListParams {
  let order_ = case order {
    "asc" -> "asc"
    _ -> "desc"
  }
  FileListParams(..config, order: option.Some(order_))
}

/// Sets the cursor used to fetch the next page of results.
pub fn list_after(config: FileListParams, after: String) -> FileListParams {
  FileListParams(..config, after: option.Some(after))
}

/// Response payload returned by the `list` endpoint.
pub type FileObjectPage {
  FileObjectPage(
    /// The individual file uploads returned by the API.
    data: List(FileObject),
    /// The ID of the first file in this page of results.
    first_id: String,
    /// The ID of the last file in this page of results.
    last_id: String,
    /// Indicates whether another page of files is available.
    has_more: Bool,
  )
}

// Decoder for list responses returned by the Files API.
fn file_object_page_decoder() -> decode.Decoder(FileObjectPage) {
  use object <- decode.field("object", decode.string)
  assert object == "list" as "Error: object must be 'list'"
  use data <- decode.field("data", decode.list(file_object_decoder()))
  use first_id <- decode.field("first_id", decode.string)
  use last_id <- decode.field("last_id", decode.string)
  use has_more <- decode.field("has_more", decode.bool)
  decode.success(FileObjectPage(data:, first_id:, last_id:, has_more:))
}

/// Metadata about a file stored on disk that is ready to be uploaded.
pub opaque type FileInfo {
  FileInfo(
    /// Path to the file on disk
    file_path: String,
    /// Friendly file name that will be shown in the dashboard.
    file_name: String,
    /// The type of file
    content_type: String,
  )
}

/// Supported purposes when uploading a file to OpenAI.
pub type FilePurpose {
  /// Files used by the Assistants API (instructions, knowledge, outputs).
  Assistants
  /// Files used for fine-tuning models.
  FineTune
  /// Images consumed by the vision fine-tuning pipeline.
  Vision
  /// Arbitrary user-provided files for flexible storage.
  UserData
  /// Datasets leveraged by eval tooling.
  Evals
}

// Convert an internal purpose enumeration into the API keyword.
fn describe_file_purpose(purpose: FilePurpose) -> String {
  case purpose {
    Assistants -> "assistants"
    Evals -> "evals"
    FineTune -> "fine-tune"
    UserData -> "user_data"
    Vision -> "vision"
  }
}

/// Expiration metadata to include when uploading a file.
pub type ExpiresAfter {
  ExpiresAfter(
    /// When the expiration countdown should begin (e.g. "last_active_at").
    anchor: String,
    /// Number of seconds after the anchor when the file expires.
    seconds: Int,
  )
}

/// Set the ExpiresAfter params.  The supported anchor param is 'created_at'
/// If seconds is outside the accepted range of 3600 (1 hour) and 2592000,
/// then it is set to 1 hour
pub fn expires_after_params(seconds: Int) -> Option(ExpiresAfter) {
  let seconds = case seconds {
    x if x >= 3600 && x <= 2_592_000 -> x
    _ -> 3600
  }

  option.Some(ExpiresAfter(anchor: "created_at", seconds:))
}

/// Status payload returned when deleting a file.
pub type FileDeleted {
  FileDeleted(
    /// Identifier of the file that was targeted for deletion.
    id: String,
    /// Whether the deletion was acknowledged by the API.
    deleted: Bool,
  )
}

// Decoder for deletion responses.
fn file_deleted_decoder() -> decode.Decoder(FileDeleted) {
  use object <- decode.field("object", decode.string)
  assert object == "file" as "Error: deletion status object != 'file'"
  use id <- decode.field("id", decode.string)
  use deleted <- decode.field("deleted", decode.bool)
  decode.success(FileDeleted(id:, deleted:))
}

/// Convenience helper for building a `File` upload payload from a path and purpose.
pub fn file_create_params(
  file_path: String,
  purpose: FilePurpose,
  expires_after: Option(ExpiresAfter),
) -> File {
  let assert Ok(file_name_ext) = string.split(file_path, "/") |> list.last()
  let assert Ok(#(file_name, file_type)) = string.split_once(file_name_ext, ".")
  let content_type = case file_type {
    "jsonl" -> "application/json"
    "pdf" -> "application/pdf"
    "txt" -> "text/plain"
    "csv" -> "text/csv"
    _ -> ""
  }
  File(
    file: FileInfo(file_path:, file_name:, content_type:),
    purpose:,
    expires_after:,
  )
}

/// Returns a baseline `FileListParams` configuration matching the OpenAI
/// SDK defaults (no cursor, limit, order, or purpose filters applied).
pub fn file_list_defaults() {
  FileListParams(
    after: option.None,
    limit: option.None,
    order: option.None,
    purpose: option.None,
  )
}

/// Full metadata describing a file uploaded to OpenAI.
pub type FileObject {
  FileObject(
    /// The size of the file, in bytes.
    bytes: Int,
    /// The Unix timestamp (in seconds) for when the file was created.
    created_at: Int,
    /// The Unix timestamp (in seconds) for when the file will expire.
    expires_at: Option(Int),
    /// The name of the file.
    filename: String,
    /// The file identifier, which can be referenced in the API endpoints.
    id: String,
    /// The object type, which is always file.
    object: String,
    /// The intended purpose of the file. Supported values are assistants,
    /// assistants_output, batch, batch_output, fine-tune, fine-tune-results,
    /// vision, and user_data.
    purpose: String,
    /// Deprecated. The current status of the file, which can be either uploaded, processed,
    /// or error.
    status: String,
    /// Deprecated. For details on why a fine-tuning training file failed validation, see
    /// the error field on fine_tuning.job.
    status_details: Option(String),
  )
}

// Decoder for FileObject values.
fn file_object_decoder() -> decode.Decoder(FileObject) {
  use object <- decode.field("object", decode.string)
  assert object == "file" as "Error: object type mismatch - 'file'"

  use bytes <- decode.field("bytes", decode.int)
  use created_at <- decode.field("created_at", decode.int)
  use expires_at <- decode.field("expires_at", decode.optional(decode.int))
  use filename <- decode.field("filename", decode.string)
  use id <- decode.field("id", decode.string)
  use purpose <- decode.field("purpose", decode.string)
  use status <- decode.field("status", decode.string)
  use status_details <- decode.field(
    "status_details",
    decode.optional(decode.string),
  )
  decode.success(FileObject(
    bytes:,
    created_at:,
    expires_at:,
    filename:,
    id:,
    object:,
    purpose:,
    status:,
    status_details:,
  ))
}

/// Uploads a file using multipart/form-data and returns the stored metadata.
pub fn create(
  client client: String,
  request file: File,
) -> Result(FileObject, error.OpenaiError) {
  let assert Ok(base_req) = request.to(files_url)
  let boundary = "----OpenAIBoundary"

  use body <- result.try(upload_multipart_body(file, boundary))
  let req =
    base_req
    |> request.prepend_header("Authorization", "Bearer " <> client)
    |> request.prepend_header(
      "Content-Type",
      "multipart/form-data; boundary=" <> boundary,
    )
    |> request.set_method(http.Post)
    |> request.set_body(body)

  use resp_bits <- result.try(
    httpc.send_bits(req) |> result.replace_error(error.HttpError),
  )
  use resp_string <- result.try(
    http_response.try_map(resp_bits, fn(body) {
      bit_array.to_string(body) |> result.replace_error(error.BadResponse)
    }),
  )
  use resp <- result.try(error.replace_error(Ok(resp_string)))
  use file_object <- result.try(
    json.parse(resp.body, file_object_decoder())
    |> result.replace_error(error.BadResponse),
  )

  Ok(file_object)
}

/// Lists files for the authenticated account honoring the provided query.
pub fn list(
  client client: String,
  request query: FileListParams,
) -> Result(FileObjectPage, error.OpenaiError) {
  let query_url = fn(query: FileListParams) {
    let FileListParams(after:, limit:, order:, purpose:) = query
    let no_query_params =
      option.values([after, order, purpose]) |> list.is_empty()
      && option.is_none(limit)
    case no_query_params {
      True -> files_url
      False -> {
        files_url
        <> "?"
        <> case query.limit {
          option.None -> ""
          option.Some(limit) -> "limit=" <> int.to_string(limit)
        }
        <> case query.after {
          option.None -> ""
          option.Some(after) -> "&after=" <> after
        }
        <> case query.order {
          option.None -> ""
          option.Some(order) -> "&order=" <> order
        }
        <> case query.purpose {
          option.None -> ""
          option.Some(purpose) -> "&purpose=" <> purpose
        }
      }
    }
  }

  let assert Ok(base_req) = request.to(query_url(query))
  let req =
    base_req
    |> request.prepend_header("Authorization", "Bearer " <> client)
    |> request.set_method(http.Get)

  use resp <- result.try(httpc.send(req) |> error.replace_error())
  use file_object_page <- result.try(
    json.parse(resp.body, file_object_page_decoder())
    |> result.replace_error(error.BadResponse),
  )

  Ok(file_object_page)
}

/// Deletes a stored file and reports whether the operation succeeded.
pub fn delete(
  client: String,
  file_id: String,
) -> Result(FileDeleted, error.OpenaiError) {
  let query = files_url <> "/" <> file_id
  let assert Ok(base_req) = request.to(query)
  let req =
    base_req
    |> request.prepend_header("Authorization", "Bearer " <> client)
    |> request.set_method(http.Delete)

  use resp <- result.try(httpc.send(req) |> error.replace_error())
  use result <- result.try(
    json.parse(resp.body, file_deleted_decoder())
    |> result.replace_error(error.BadResponse),
  )

  Ok(result)
}

/// Retrieves the stored metadata for a file by ID.
pub fn retrieve(
  client: String,
  file_id: String,
) -> Result(FileObject, error.OpenaiError) {
  let query = files_url <> "/" <> file_id
  let assert Ok(base_req) = request.to(query)
  let req =
    base_req
    |> request.prepend_header("Authorization", "Bearer " <> client)
    |> request.set_method(http.Get)

  use resp <- result.try(httpc.send(req) |> error.replace_error())
  use result <- result.try(
    json.parse(resp.body, file_object_decoder())
    |> result.replace_error(error.BadResponse),
  )

  Ok(result)
}

/// Downloads the raw bits for a stored file via `/files/{id}/content`
pub fn content(
  client: String,
  file_id: String,
) -> Result(BitArray, error.OpenaiError) {
  let query = files_url <> "/" <> file_id <> "/content"
  let assert Ok(base_req) = request.to(query)
  let req =
    base_req
    |> request.prepend_header("Authorization", "Bearer " <> client)
    |> request.prepend_header("Accept", "application/binary")
    |> request.set_method(http.Get)
  let req = request.map(req, bit_array.from_string)

  use resp <- result.try(
    httpc.send_bits(req) |> result.replace_error(error.HttpError),
  )

  case resp.status {
    200 -> Ok(resp.body)
    _ -> {
      use resp_string <- result.try(
        http_response.try_map(resp, fn(body) {
          bit_array.to_string(body) |> result.replace_error(error.BadResponse)
        }),
      )
      case error.replace_error(Ok(resp_string)) {
        Error(err) -> Error(err)
        Ok(_) -> Error(error.Unknown)
      }
    }
  }
}

// Builds the multipart/form-data payload used by `create/2`.
fn upload_multipart_body(
  request: File,
  boundary: String,
) -> Result(BitArray, error.OpenaiError) {
  let File(FileInfo(file_path, file_name, content_type), purpose, expires_after) =
    request
  use file_bytes <- result.try(
    simplifile.read_bits(file_path) |> result.replace_error(error.File),
  )

  let dash = "--" <> boundary <> "\r\n"
  let parts =
    dash
    <> "Content-Disposition: form-data; name=\"purpose\"\r\n\r\n"
    <> describe_file_purpose(purpose)
    <> "\r\n"
    <> case expires_after {
      option.Some(ExpiresAfter(anchor, seconds)) ->
        dash
        <> "Content-Disposition: form-data; name=\"expires_after[anchor]\"\r\n\r\n"
        <> anchor
        <> "\r\n"
        <> dash
        <> "Content-Disposition: form-data; name=\"expires_after[seconds]\"\r\n\r\n"
        <> int.to_string(seconds)
        <> "\r\n"
      option.None -> ""
    }

  let file_header =
    dash
    <> "Content-Disposition: form-data; name=\"file\"; filename=\""
    <> file_name
    <> "\"\r\n"
    <> "Content-Type: "
    <> case content_type {
      "" -> "application/octet-stream"
      _ -> content_type
    }
    <> "\r\n\r\n"

  Ok(
    bit_array.concat([
      bit_array.from_string(parts),
      bit_array.from_string(file_header),
      file_bytes,
      bit_array.from_string("\r\n--" <> boundary <> "--\r\n"),
    ]),
  )
}
