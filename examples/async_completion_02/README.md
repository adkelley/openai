# async_completion_02

## Overview

This example demonstrates streaming chat completions using the `openai`
Gleam SDK. It enables server-side streaming, consumes chunks as they arrive,
and prints the assistant's answer progressively.

## Prerequisites

- Set the `OPENAI_API_KEY` environment variable before running the example.
- The program prints a fixed question; edit `prompt` in
  `src/async_completion_02.gleam` to experiment with other inputs.

## Running the example

```sh
gleam run
```

The program will:

1. Load `OPENAI_API_KEY` from the environment.
2. Configure a chat completion request with `stream: True`.
3. Invoke `openai/completions.stream_create/3`.
4. Iterate over each streamed delta and print partial content as it arrives.

Refer to `src/async_completion_02.gleam` for additional commentary on handling
the stream lifecycle.
