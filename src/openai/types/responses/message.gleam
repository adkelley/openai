import gleam/dynamic/decode.{type Decoder}
import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, None, Some}
import openai/types/helpers
import openai/types/logprob.{type LogProb}
import openai/types/responses/content.{type Content}
import openai/types/role.{type Role}

pub type Message {
  Message(content: List(Content), role: Role, status: Option(Status))
}

pub fn encode_message(message: Message) -> Json {
  [
    #("type", json.string("message")),
    #("content", json.array(message.content, content.encode_content)),
    #("role", role.encode_role(message.role)),
  ]
  |> helpers.encode_option("status", message.status, encode_status)
  |> json.object
}

pub fn new() -> Message {
  Message(content: [], role: role.User, status: None)
}

pub fn with_content(message: Message, content: List(Content)) -> Message {
  Message(..message, content: content)
}

pub fn with_role(message: Message, role: Role) -> Message {
  Message(..message, role: role)
}

pub fn with_status(message: Message, status: Status) -> Message {
  Message(..message, status: Some(status))
}

/// A citation to a file.
pub type FileCitation {
  FileCitation(
    /// The ID of the file.
    file_id: String,
    /// The filename of the file cited.
    filename: String,
    /// The index of the file in the list of files.
    index: Int,
    //type: "file_citation"
    //The type of the file citation. Always file_citation.
  )
}

fn encode_file_citation(file_citation: FileCitation) -> Json {
  json.object([
    #("file_id", json.string(file_citation.file_id)),
    #("filename", json.string(file_citation.filename)),
    #("index", json.int(file_citation.index)),
    #("type", json.string("file_citation")),
  ])
}

fn decode_file_citation() -> Decoder(FileCitation) {
  use file_id <- decode.field("file_id", decode.string)
  use filename <- decode.field("filename", decode.string)
  use index <- decode.field("index", decode.int)
  decode.success(FileCitation(file_id:, filename:, index:))
}

/// A citation for a web resource used to generate a model response.
pub type URLCitation {
  URLCitation(
    /// The index of the last character of the URL citation in the message.
    end_index: Int,
    /// The index of the first character of the URL citation in the message.
    start_index: Int,
    /// The title of the web resource.
    title: String,
    // The type of the URL citation. Always url_citation.
    // type: url_citation"
    /// The URL of the web resource.
    url: String,
  )
}

fn encode_url_citation(url_citation: URLCitation) -> Json {
  json.object([
    #("end_index", json.int(url_citation.end_index)),
    #("start_index", json.int(url_citation.start_index)),
    #("title", json.string(url_citation.title)),
    #("type", json.string("url_citation")),
    #("url", json.string(url_citation.url)),
  ])
}

fn decode_url_citation() -> Decoder(URLCitation) {
  use end_index <- decode.field("end_index", decode.int)
  use start_index <- decode.field("start_index", decode.int)
  use title <- decode.field("title", decode.string)
  use url <- decode.field("url", decode.string)
  decode.success(URLCitation(end_index:, start_index:, title:, url:))
}

/// citation for a container file used to generate a model response.
pub type ContainerFileCitation {
  ContainerFileCitation(
    /// The ID of the container file.
    container_id: String,
    /// The index of the last character of the container file citation in the message.
    end_index: Int,
    /// The ID of the file.
    file_id: String,
    /// The filename of the container file cited.
    filename: String,
    /// The index of the first character of the container file citation in the message.
    start_index: Int,
    // type: "container_file_citation"
    // The type of the container file citation. Always container_file_citation.
  )
}

fn encode_container_file_citation(
  container_file_citation: ContainerFileCitation,
) -> Json {
  json.object([
    #("container_id", json.string(container_file_citation.container_id)),
    #("end_index", json.int(container_file_citation.end_index)),
    #("file_id", json.string(container_file_citation.file_id)),
    #("filename", json.string(container_file_citation.filename)),
    #("start_index", json.int(container_file_citation.start_index)),
    #("type", json.string("container_file_citation")),
  ])
}

fn decode_container_file_citation() -> Decoder(ContainerFileCitation) {
  use container_id <- decode.field("container_id", decode.string)
  use end_index <- decode.field("end_index", decode.int)
  use file_id <- decode.field("file_id", decode.string)
  use filename <- decode.field("filename", decode.string)
  use start_index <- decode.field("start_index", decode.int)
  decode.success(ContainerFileCitation(
    container_id:,
    end_index:,
    file_id:,
    filename:,
    start_index:,
  ))
}

/// A path to a file.
pub type FilePath {
  FilePath(
    /// The ID of the file.
    file_id: String,
    /// The index of the file in the list of files.
    index: Int,
    // type: "file_path"
    // The type of the file path. Always file_path.
  )
}

fn encode_file_path(file_path: FilePath) -> Json {
  json.object([
    #("file_id", json.string(file_path.file_id)),
    #("index", json.int(file_path.index)),
    #("type", json.string("file_path")),
  ])
}

fn decode_file_path() -> Decoder(FilePath) {
  use file_id <- decode.field("file_id", decode.string)
  use index <- decode.field("index", decode.int)
  decode.success(FilePath(file_id:, index:))
}

pub type Annotation {
  FileCitationItem(FileCitation)
  URLCitationItem(URLCitation)
  ContainerFileCitationItem(ContainerFileCitation)
  FilePathItem(FilePath)
}

fn encode_annotation(annotation: Annotation) -> Json {
  case annotation {
    FileCitationItem(b) -> encode_file_citation(b)
    URLCitationItem(b) -> encode_url_citation(b)
    ContainerFileCitationItem(b) -> encode_container_file_citation(b)
    FilePathItem(b) -> encode_file_path(b)
  }
}

fn decode_annotation() -> Decoder(Annotation) {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "file_citation" -> decode_file_citation() |> decode.map(FileCitationItem)
    "url_citation" -> decode_url_citation() |> decode.map(URLCitationItem)
    "container_file_citation" ->
      decode_container_file_citation() |> decode.map(ContainerFileCitationItem)
    "file_path" -> decode_file_path() |> decode.map(FilePathItem)
    _ -> panic as type_
  }
}

pub type OutputText {
  OutputText(
    /// The annotations of the text output.
    annotations: List(Annotation),
    /// Token-level log probability information for the text output.
    logprobs: Option(List(LogProb)),
    /// The text output from the model.
    text: String,
  )
}

fn encode_output_text(output_text: OutputText) -> Json {
  [
    #("type", json.string("output_text")),
    #("annotations", json.array(output_text.annotations, encode_annotation)),
    #("text", json.string(output_text.text)),
  ]
  |> helpers.encode_option_list(
    "logprobs",
    output_text.logprobs,
    logprob.encode_logprob,
  )
  |> json.object
}

pub type OutputRefusal {
  OutputRefusal(refusal: String)
}

fn encode_refusal_content(output_refusal: OutputRefusal) -> Json {
  json.object([
    #("type", json.string("refusal")),
    #("refusal", json.string(output_refusal.refusal)),
  ])
}

pub type OutputMessageContent {
  OutputTextItem(OutputText)
  OutputRefusalItem(OutputRefusal)
}

fn encode_output_message_content(
  output_message_content: OutputMessageContent,
) -> Json {
  case output_message_content {
    OutputTextItem(b) -> encode_output_text(b)
    OutputRefusalItem(b) -> encode_refusal_content(b)
  }
}

pub fn decode_output_message_content() -> Decoder(OutputMessageContent) {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "output_text" -> {
      use annotations <- decode.field(
        "annotations",
        decode.list(decode_annotation()),
      )
      use logprobs <- decode.field(
        "logprobs",
        decode.optional(decode.list(logprob.decode_logprob())),
      )
      use text <- decode.field("text", decode.string)
      decode.success(OutputTextItem(OutputText(annotations:, logprobs:, text:)))
    }
    "refusal" -> {
      use refusal <- decode.field("refusal", decode.string)
      decode.success(OutputRefusalItem(OutputRefusal(refusal:)))
    }
    _ -> panic as type_
  }
}

pub fn decode_output_message_texts() -> Decoder(List(List(String))) {
  decode.at(
    ["output"],
    decode.list(decode.at(
      ["content"],
      decode.list(decode.at(["text"], decode.string)),
    )),
  )
}

pub type Status {

  InProgress
  Completed
  Incomplete
}

fn encode_status(status: Status) -> Json {
  case status {
    InProgress -> "in_progress"
    Completed -> "completed"
    Incomplete -> "incomplete"
  }
  |> json.string
}

fn decode_status() -> Decoder(Status) {
  decode.string
  |> decode.map(fn(status) {
    case status {
      "in_progress" -> InProgress
      "completed" -> Completed
      "incomplete" -> Incomplete
      _ -> panic as status
    }
  })
}

pub fn response_output_message_status(
  config: ResponseOutputMessage,
  status: Status,
) -> ResponseOutputMessage {
  ResponseOutputMessage(..config, status: status)
}

pub type ResponseOutputMessage {
  ResponseOutputMessage(
    /// The unique ID of the output message.
    id: String,
    /// The content of the output message.
    content: List(OutputMessageContent),
    /// The role of the output message. Always assistant.
    role: Role,
    /// The status of the message input. One of in_progress, completed, or
    /// incomplete. Populated when input items are returned via API.
    status: Status,
    // The type of the output message. Always `message`.
    // type: "message"
  )
}

pub fn encode_response_output_message(
  response_output_message: ResponseOutputMessage,
) -> Json {
  json.object([
    #("id", json.string(response_output_message.id)),
    #("type", json.string("message")),
    #(
      "content",
      json.array(response_output_message.content, encode_output_message_content),
    ),
    case response_output_message.role {
      role.Assistant -> #(
        "role",
        role.encode_role(response_output_message.role),
      )
      // Force the role to be Assistant
      _ -> #("role", role.encode_role(role.Assistant))
    },
    #("status", encode_status(response_output_message.status)),
  ])
}

pub fn decode_response_output_message() -> Decoder(ResponseOutputMessage) {
  use id <- decode.field("id", decode.string)
  use content <- decode.field(
    "content",
    decode.list(decode_output_message_content()),
  )
  use role <- decode.field("role", decode.string)
  use status <- decode.field("status", decode_status())
  let role = case role {
    "assistant" -> role.Assistant
    _ -> panic as role
  }
  decode.success(ResponseOutputMessage(id:, content:, role:, status:))
}

pub type Phase {
  Commentary
  FinalAnswer
}

fn encode_phase(phase: Option(Phase)) -> Json {
  case phase {
    Some(s) ->
      case s {
        Commentary -> json.string("commentary")
        FinalAnswer -> json.string("final_answer")
      }
    None -> json.null()
  }
}

pub type EasyInputContent {
  EasyText(String)
  Content(List(Content))
}

fn encode_easy_content(content: EasyInputContent) -> Json {
  case content {
    EasyText(text) -> json.string(text)
    Content(content) -> json.array(content, content.encode_content)
  }
}

pub type EasyInputMessage {
  EasyInputMessage(
    /// The role of the message input.
    role: Role,
    // TODO Change to content?
    content: EasyInputContent,
    /// The phase of the message, when provided.
    phase: Option(Phase),
    // type: "message"
  )
}

pub fn encode_easy_input_message(easy_input_message: EasyInputMessage) -> Json {
  json.object([
    #("role", role.encode_role(easy_input_message.role)),
    #("phase", encode_phase(easy_input_message.phase)),
    #("type", json.string("message")),
    #("content", encode_easy_content(easy_input_message.content)),
  ])
}
