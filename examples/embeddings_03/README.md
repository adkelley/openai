# embeddings_03

## Overview

This example shows how to generate embeddings with the `openai` Gleam SDK. It
sends a short sentence to the Embeddings API, prints the model used, and echoes
the resulting vector payload.

## Prerequisites

- Set the `OPENAI_API_KEY` environment variable before running the example.
- Update the `input` string in `src/embeddings_03.gleam` if you would like to
  embed different text.

## Running the example

```sh
gleam run
```

The program will:

1. Load `OPENAI_API_KEY` from the environment.
2. Select the default embeddings model exposed by the SDK.
3. Submit an embedding request and print the API response.

Review `src/embeddings_03.gleam` for additional notes on configuring optional
parameters.
