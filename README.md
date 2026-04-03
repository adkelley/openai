# openai_gleam

`openai_gleam` is a Gleam SDK for the OpenAI API. It provides typed request and
response structures, multipart helpers for file and audio uploads, streaming
support for Chat Completions, and builder-style helpers for the Responses API.

Further documentation can be found at <https://hexdocs.pm/openai_gleam/>.

## Overview

- Responses API helpers and typed tool payloads
- Chat Completions support, including streaming over SSE
- Audio transcriptions and translations via multipart form uploads
- Files API upload, list, retrieve, download, and delete helpers
- Embeddings support with typed vectors and usage data
- Shared error mapping through `OpenAIError`

## Installation

The examples in this repository currently depend on the GitHub repository
directly:

```toml
[dependencies]
openai_gleam = { git = "https://github.com/adkelley/openai_gleam", ref = "main" }
```

Set `OPENAI_API_KEY` in your environment before running any examples.

## Usage

### Chat Completions

```gleam
import gleam/io
import gleam/list
import openai/client
import openai/completions
import openai/error.{type OpenAIError}
import openai/types/completion
import openai/types/role.{System, User}

pub fn main() -> Result(Nil, OpenAIError) {
  let assert Ok(client) = client.new()

  let messages =
    completions.add_message([], System, "You are a helpful assistant")
    |> completions.add_message(User, "Why is the sky blue?")

  let config = completion.new()
  let assert Ok(completion) =
    completions.create(client, config, messages)

  let content =
    list.fold(completion.choices, "", fn(acc, choice) {
      acc <> choice.message.content
    })

  io.println(content)
  Ok(Nil)
}
```

Use `completions.stream_create/3` and `stream_create_handler/1` for streaming
Chat Completions.

### Responses API

```gleam
import gleam/io
import gleam/option.{Some}
import openai/error.{type OpenAIError}
import openai/client
import openai/responses
import openai/types/responses/response

pub fn main() -> Result(Nil, OpenAIError) {
  let assert Ok(client) = client.new()

  let request =
    responses.new()
    |> responses.with_model("gpt-5-mini")
    |> responses.with_input(response.Text("Give me two fun facts about Gleam."))

  let assert Ok(resp) = responses.create(client, request)
  let assert Some(text) = resp.output_text
  io.println(text)
  Ok(Nil)
}
```

The Responses API helpers expose typed tool definitions for web search, MCP,
shell, function calling, code interpreter, image input, and related response
items.

### Audio Transcriptions

```gleam
import gleam/io
import openai/audio
import openai/client
import openai/error.{type OpenAIError}
import openai/types/audio/transcription

pub fn main() -> Result(Nil, OpenAIError) {
  let assert Ok(client) = client.new()

  let assert Ok(transcript) =
    transcription.new()
    |> transcription.with_file("./audio.mp3")
    |> audio.create_transcription(client, _)

  io.println(transcript.text)
  Ok(Nil)
}
```

### Audio Translations

```gleam
import gleam/io
import openai/audio
import openai/client
import openai/error.{type OpenAIError}
import openai/types/audio/translation

pub fn main() -> Result(Nil, OpenAIError) {
  let assert Ok(client) = client.new()

  let assert Ok(transcript) =
    translation.new()
    |> translation.with_file("./audio.m4a")
    |> audio.create_translation(client, _)

  io.println(transcript.text)
  Ok(Nil)
}
```

### Files API

```gleam
import openai/client
import openai/files

pub fn main() -> Nil {
  let assert Ok(client) = client.new()

  let assert Ok(file) =
    files.new_file(
      "./mydata.jsonl",
      files.Evals,
      files.expires_after(3600),
    )
    |> files.create(client, _)

  let _ = files.retrieve(client, file.id)
  let _ = files.content(client, file.id)
  let _ = files.delete(client, file.id)

  Nil
}
```

### Embeddings

```gleam
import openai/embeddings
import openai/error.{type OpenAIError}
import openai/types/embedding
import openai/client

pub fn main() -> Result(Nil, OpenAIError) {
  let assert Ok(client) = client.new()

  let request =
    embedding.new()
    |> embedding.with_input(embedding.StringList(["Gleam is a friendly language."]))
    |> embedding.with_encoding_format(embedding.Float)

  let assert Ok(_response) = embeddings.create(client, request)
  Ok(Nil)
}
```

## Examples

- `examples/completion_01` - synchronous Chat Completions
- `examples/async_completion_02` - streaming Chat Completions
- `examples/embeddings_03` - embedding generation
- `examples/web_search_04` - web search preview with the Responses API
- `examples/files_api_05` - Files API upload, download, list, and cleanup
- `examples/image_input_06` - image input with the Responses API
- `examples/mcp_07` - MCP tools through the Responses API
- `examples/fn_calling_08` - function calling with the Responses API
- `examples/shell_cmds_09` - shell tool calls with the Responses API
- `examples/transcription_10` - audio transcription
- `examples/translation_11` - audio translation
- `examples/skills_12` - local skills with shell and web search
- `examples/structured_output_13` - JSON schema constrained structured output

## Development

```sh
gleam check
gleam test
```

## Notes

- The audio endpoints use `multipart/form-data` rather than JSON request
  bodies.
- The endpoint helpers live in `openai/audio`, while the typed audio request
  and response structures live in `openai/types/audio/transcription` and
  `openai/types/audio/translation`.
