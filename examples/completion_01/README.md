# completion_01

## Overview

This example issues a basic chat completion request with the `openai` Gleam SDK.
It sends a fixed prompt through the Chat Completions API, collects the returned
assistant message, and prints the response to standard output.

## Prerequisites

- Set the `OPENAI_API_KEY` environment variable before running the example.
- Adjust the hard-coded prompt in `src/completion_01.gleam` if you would like to
  query a different question.

## Running the example

```sh
gleam run
```

The program will:

1. Load `OPENAI_API_KEY` from the environment.
2. Build a minimal chat history with a system primer and a single user prompt.
3. Call `openai/chat/completions.create/3` and print the assistant content.

See `src/completion_01.gleam` for inline comments that explain each step in more
detail.
