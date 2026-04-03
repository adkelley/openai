# image_input_06

This example sends a text prompt and an image URL to the Responses API and
prints the assistant's answer. It uses the current client-based request flow
and constructs a message containing both text and image content.

## Prerequisites

- Set `OPENAI_API_KEY` in your environment.
- Update `image_url` in `src/image_input_06.gleam` if you want to analyze a
  different image.

## Running

```sh
gleam run
```

The example builds a `message.default_message(...)`, wraps it in
`response.Items`, applies `responses.instructions/2`, and prints the first
output text item returned by the API.
