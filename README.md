# openai

`openai` is an SDK for the OpenAI API written in Gleam. It wraps the REST APIs with
typed request/response structures, streaming support, and helpful utilities so
Gleam applications can call the Responses, Chat Completions, Files, and Embeddings
endpoints without hand-writing JSON plumbing.

## Overview

- Typed models, roles, and payloads shared across OpenAI endpoints.
- Chat completions with helpers for building message sets.
- Server Sent Events streaming support for `/v1/chat/completions`.
- `/v1/responses` support with builders for tool selection (web search, etc).
- Files API utilities for uploading datasets, retrieving metadata, and downloading content.
- Embeddings with strongly typed vectors and usage data.
- Consistent error mapping into an `OpenaiError` union.

Further documentation can be found at <https://hexdocs.pm/openai/>.

## Installation

```sh
gleam add openai@1
```

Set `OPENAI_API_KEY` in your environment before running any of the examples.

## Usage

### Chat completions

```gleam
import envoy
import gleam/io
import gleam/list
import openai/completions
import openai/types as shared

pub fn main() -> Nil {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let messages =
    completions.add_message([], shared.System, "You are a helpful assistant")
    |> completions.add_message(shared.User, "Why is the sky blue?")

  let assert Ok(completion) =
    completions.create(api_key, completions.default_config(), messages)

  let answer =
    list.fold(completion.choices, "", fn(acc, choice) {
      acc <> choice.message.content
    })

  io.println(answer)
  Nil
}
```

Use `completions.stream_create/3` and `stream_create_handler/1` when you want to
consume Server Sent Events as the model produces tokens. See
`examples/async_completion_02` for a full streaming loop.

### Responses API

```gleam
import envoy
import gleam/io
import gleam/list
import openai/responses
import openai/responses/types/response as response
import openai/types as shared

pub fn main() -> Nil {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let request =
    responses.default_request()
    |> responses.model(shared.GPT41Mini)
    |> responses.input("Give me two fun facts about Gleam.")

  let assert Ok(resp) = responses.create(api_key, request)

  resp.output
  |> list.each(fn(item) {
    case item {
      response.Message(content, _, _, _) ->
        content
        |> list.each(fn(part) {
          case part {
            response.OutputText(_, text) -> io.println(text)
          }
        })
      response.WebSearchCall(_, _, _) ->
        io.println("-> The model issued a web search call.")
    }
  })
}
```

The request builder exposes helpers for model selection, input text, tool choice
and tool registration. Tool payloads (such as web search filters and locations)
are typed, so you can confidently expose them to the model.

### Files API

```gleam
import envoy
import gleam/io
import openai/files
import simplifile

pub fn main() -> Nil {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let assert Ok(file) =
    files.file_create_params(
      "./mydata.jsonl",
      files.Evals,
      files.expires_after_params(3600),
    )
    |> files.create(api_key, _)

  // Inspect the remote metadata before downloading the contents.
  let assert Ok(metadata) = files.retrieve(api_key, file.id)
  io.debug(metadata)

  let assert Ok(bytes) = files.content(api_key, file.id)
  let assert Ok(_) = simplifile.write_bits("./download.jsonl", bytes)

  let assert Ok(_) = files.delete(api_key, file.id)
  Nil
}
```

Use the provided helpers to control file purposes, expiry, and list results. The
files example demonstrates chaining these utilities together.

### Embeddings

```gleam
import envoy
import gleam/io
import gleam/int
import gleam/list
import gleam/option
import openai/embeddings

pub fn main() -> Nil {
  let assert Ok(api_key) = envoy.get("OPENAI_API_KEY")

  let assert Ok(response) =
    embeddings.create(
      api_key,
      "Gleam is a friendly language.",
      embeddings.default_model,
      option.None,
      option.None,
      option.None,
    )

  let assert option.Some(first) = list.first(response.data)
  io.println("Embedding length: " <> int.to_string(list.length(first.embedding)))
}
```

## Examples

- `examples/completion_01` – synchronous chat completions.
- `examples/async_completion_02` – streaming chat completions over SSE.
- `examples/embeddings_03` – embedding generation helpers.
- `examples/web_search_04` – calling the Responses API with the web search tool.
- `examples/files_api_05` – end-to-end Files API upload, download, and cleanup.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## TODO
- Add streaming support to responses API
- File search
