/// Issues a Responses API call that pairs a text prompt with a remote image.
import gleam/dynamic/decode
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import openai/client
import openai/error.{type OpenAIError}
import openai/responses
import openai/types/responses/content
import openai/types/responses/message
import openai/types/responses/response
import openai/types/role

/// Builds an image-aware Responses request and prints the returned payload.
pub fn main() -> Result(Nil, OpenAIError) {
  let assert Ok(client) = client.new()

  let image_url =
    "https://cdn.pixabay.com/photo/2015/11/07/11/22/mountains-1031075_960_720.jpg"

  let prompt = "What is in this image?"
  io.println("\nPrompt: " <> prompt)
  io.println("Image Url: " <> image_url)

  let content =
    content.new_text("What is in this image?")
    |> content.TextContentItem
    |> list.wrap
    |> list.prepend(
      content.new_image()
      |> content.with_image_url(image_url)
      |> content.ImageContentItem,
    )

  let input =
    message.new()
    |> message.with_content(content)
    |> message.with_role(role.User)
    |> response.MessageItem
    |> list.wrap
    |> response.Items

  let instructions = "You are a chat bot that talks like a pirate"

  let request =
    responses.new()
    |> responses.with_model("gpt-5-mini")
    |> responses.with_input(input)
    |> responses.with_instructions(instructions)

  let assert Ok(text) =
    responses.create_with_decoder(client, request, decode_output_message_text())
  io.println("\n" <> text)
  Ok(Nil)
}

fn decode_output_message_text() -> decode.Decoder(String) {
  use outputs <- decode.field("output", decode.list(decode_output_item_text()))
  case first_non_empty_text(option.values(outputs)) {
    Some(text) -> decode.success(text)
    None -> decode.failure("", expected: "non-empty message output text")
  }
}

fn decode_output_item_text() -> decode.Decoder(Option(String)) {
  use type_ <- decode.field("type", decode.string)
  case type_ {
    "message" ->
      decode.at(["content"], decode.at([0], decode.at(["text"], decode.string)))
      |> decode.map(Some)
    _ -> decode.success(None)
  }
}

fn first_non_empty_text(items: List(String)) -> Option(String) {
  case items {
    [text, ..rest] ->
      case string.trim(text) {
        "" -> first_non_empty_text(rest)
        _ -> Some(text)
      }
    [] -> None
  }
}
