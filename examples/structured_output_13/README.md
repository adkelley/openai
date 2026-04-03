# structured_output_13

This example demonstrates structured output with the Responses API. It sends a
free-form support ticket, constrains the model to a JSON Schema, decodes the
returned JSON into a Gleam type, and prints the extracted ticket fields.

## Prerequisites

- Set `OPENAI_API_KEY` in your environment.
- Edit the support ticket text in `src/structured_output_13.gleam` if you want
  to try a different extraction scenario.

## Running

```sh
gleam run
```

The example uses `text.format = json_schema` and then parses the model's JSON
response into a typed Gleam record.
