# completion_01

This example shows a basic Chat Completions request. It builds a small chat
history with one system message and one user message, then prints the assistant
reply.

## Prerequisites

- Set `OPENAI_API_KEY` in your environment.
- Edit `prompt` in `src/completion_01.gleam` if you want to try a different
  request.

## Running

```sh
gleam run
```

The example uses `openai/completions.create/3` and then folds over the returned
choices to print the generated content.
