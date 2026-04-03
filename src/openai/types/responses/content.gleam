import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import openai/types/helpers

pub type Content {
  TextContentItem(TextContent)
  ImageContentItem(ImageContent)
  FileContentItem(FileContent)
}

pub fn encode_content(content: Content) -> Json {
  case content {
    TextContentItem(text_content) -> encode_text_content(text_content)
    ImageContentItem(image_content) -> encode_image_content(image_content)
    FileContentItem(file_content) -> encode_file_content(file_content)
  }
}

pub type TextContent {
  TextContent(
    /// The text input to the model.
    text: String,
    // type: "input_text"
  )
}

pub fn new_text(text: String) -> TextContent {
  TextContent(text:)
}

fn encode_text_content(text_content: TextContent) -> Json {
  json.object([
    #("type", json.string("input_text")),
    #("text", json.string(text_content.text)),
  ])
}

pub type ImageContent {
  ImageContent(
    /// The detail level of the image to be sent to the model. One of high, low, or auto.
    /// Defaults to auto.
    detail: String,
    /// The ID of the file to be sent to the model.
    file_id: Option(String),
    /// The URL of the image to be sent to the model. A fully qualified URL or base64 encoded
    /// image in a data URL.
    image_url: Option(String),
    // type: "input_image"
  )
}

pub fn new_image() -> ImageContent {
  ImageContent(detail: "auto", file_id: None, image_url: None)
}

pub fn with_detail(image_content: ImageContent, detail: String) {
  case detail {
    "high" | "low" | "auto" -> ImageContent(..image_content, detail: detail)
    _ -> panic as "detail must be 'high', 'low', or 'auto'"
  }
}

pub fn with_image_file_id(image_content: ImageContent, file_id: String) {
  ImageContent(..image_content, file_id: Some(file_id))
}

pub fn with_image_url(image_content: ImageContent, image_url: String) {
  ImageContent(..image_content, image_url: Some(image_url))
}

fn encode_image_content(image_content: ImageContent) {
  [
    #("type", json.string("input_image")),
    #("detail", json.string(image_content.detail)),
  ]
  |> helpers.encode_option("file_id", image_content.file_id, json.string)
  |> helpers.encode_option("image_url", image_content.image_url, json.string)
  |> json.object
}

pub type FileContent {
  FileContent(
    //type: "input_file"
    /// The content of the file to be sent to the model.
    file_data: Option(String),
    /// The ID of the file to be sent to the model.
    file_id: Option(String),
    /// The URL of the file to be sent to the model.
    file_url: Option(String),
    /// The name of the file to be sent to the model.
    filename: Option(String),
  )
}

pub fn new_file() -> FileContent {
  FileContent(file_data: None, file_id: None, file_url: None, filename: None)
}

pub fn with_file_data(file_content: FileContent, file_data: String) -> FileContent {
  FileContent(..file_content, file_data: Some(file_data))
}

pub fn with_file_id(file_content: FileContent, file_id: String) -> FileContent {
  FileContent(..file_content, file_id: Some(file_id))
}

pub fn with_file_url(file_content: FileContent, file_url: String) -> FileContent {
  FileContent(..file_content, file_url: Some(file_url))
}

pub fn with_filename(file_content: FileContent, filename: String) -> FileContent {
  FileContent(..file_content, filename: Some(filename))
}

fn encode_file_content(file_content: FileContent) -> Json {
  [
    #("type", json.string("input_file")),
  ]
  |> helpers.encode_option("file_data", file_content.file_data, json.string)
  |> helpers.encode_option("file_id", file_content.file_id, json.string)
  |> helpers.encode_option("file_url", file_content.file_url, json.string)
  |> helpers.encode_option("filename", file_content.filename, json.string)
  |> json.object
}
