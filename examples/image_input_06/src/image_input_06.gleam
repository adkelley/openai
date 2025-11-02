/// Issues a Responses API call that pairs a text prompt with a remote image.
import envoy
import gleam/io
import gleam/option.{None, Some}
import openai/error.{type OpenaiError}
import openai/responses
import openai/responses/types/request
import openai/responses/types/response.{type Response}
import openai/types as shared

/// Builds an image-aware Responses request and prints the returned payload.
pub fn main() -> Result(Response, OpenaiError) {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let image_url =
    "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg"
  let prompt = "What is in this image?"
  io.println("\nPrompt: " <> prompt)
  io.println("Image Url: " <> image_url)

  let input_list_item =
    request.InputListItemMessage(request.InputMessage(
      role: "user",
      content: request.ContentInputList([
        request.ContentItemText(text: "What is in this image?"),
        request.ContentItemImage(
          detail: "auto",
          file_id: None,
          image_url: Some(image_url),
        ),
      ]),
    ))
  let input = request.InputList([input_list_item])
  let instructions = "You are a coding assistant that talks like a pirate"

  let config =
    responses.default_request()
    |> responses.model(shared.GPT41)
    |> responses.input(input)
    |> responses.instructions(Some(instructions))

  let response = responses.create(api_key, config)
  echo response
}
