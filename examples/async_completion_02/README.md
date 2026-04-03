# async_completion_02

This example demonstrates streaming Chat Completions with the `openai` Gleam
SDK. It sends a fixed prompt, enables `stream: True`, and prints each delta as
it arrives.

## Prerequisites

- Set `OPENAI_API_KEY` in your environment.
- Update `prompt` in `src/async_completion_02.gleam` if you want a different
  question.

## Running

```sh
gleam run
```

The program starts a streaming completion with
`openai/completions.stream_create/3`, consumes events with
`stream_create_handler/1`, and prints the final answer incrementally.
