# image_input_06

Example Gleam project that demonstrates how to call the OpenAI Responses API
with both text and image input. The program sends a prompt and an image URL to
the `gpt-4.1` model, sets the request `instructions`, and prints the model's
analysis of the photo.

## Prerequisites
- Gleam 1.1 or newer
- An OpenAI API key with access to the Responses API
- Network access to fetch the example image (or update the URL to one you host)

## Running The Example
1. Export your API key so the example can authenticate:
   ```sh
   export OPENAI_API_KEY="sk-..."
   ```
2. Start the program:
   ```sh
   gleam run
   ```
   The app prints the prompt, the image URL, and the structured response payload
   returned by the API.

## Customising The Request
- **Prompt** – Update the `prompt` string in `src/image_input_06.gleam` to ask a
  different question about the image contents.
- **Instructions** – Change the `instructions` string in `src/image_input_06.gleam`
  to steer the assistant's behaviour or voice.
- **Image source** – Point `image_url` at a different image, or change the code
  to upload a file and use `file_id` instead.
- **Model options** – Adjust the request pipeline where `responses.model/2` and
  `responses.input/2` are configured to target a different model or tweak other
  request fields.

## Development Commands
```sh
gleam build # Build the example
gleam run   # Run the example
```
