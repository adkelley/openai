# image_input_06

This example sends a text prompt and an image URL to the Responses API and
prints the assistant's answer. It constructs a message containing both text and
image content, then uses `responses.create_with_decoder/3` to decode the final
text directly.

## Prerequisites

- Set `OPENAI_API_KEY` in your environment.
- Update `image_url` in `src/image_input_06.gleam` if you want to analyze a
  different image.

## Running

```sh
gleam run
```

The example builds a multimodal input message, applies
`responses.with_instructions/2`, and uses a small custom decoder for the first
non-empty output text item returned by the API.
