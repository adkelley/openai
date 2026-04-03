# embeddings_03

This example generates an embedding for a short text input. It prints the input
string, prints the default model name, and then sends the request to the
Embeddings API.

## Prerequisites

- Set `OPENAI_API_KEY` in your environment.
- Edit `input` in `src/embeddings_03.gleam` if you want to embed different
  text.

## Running

```sh
gleam run
```

The example uses `openai/embeddings.create/6` with the SDK default embedding
model and leaves the optional dimensions, encoding format, and user fields
unset.
