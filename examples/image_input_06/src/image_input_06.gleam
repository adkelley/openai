/// Issues a Responses API call that pairs a text prompt with a remote image.
import gleam/io
import gleam/list
import openai/client
import openai/error.{type OpenAIError}
import openai/responses
import openai/types/responses/content
import openai/types/responses/message
import openai/types/responses/response
import openai/types/role

/// Builds an image-aware Responses request and prints the returned payload.
pub fn main() -> Result(response.Response, OpenAIError) {
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

  let assert Ok(response) = responses.create(client, request)
  let assert Ok(response.ResponseOutputMessageItem(message.ResponseOutputMessage(
    content:,
    ..,
  ))) = list.last(response.output)
  let assert Ok(message.OutputTextItem(message.OutputText(text:, ..))) =
    list.first(content)
  io.println("\n" <> text)
  Ok(response)
}
