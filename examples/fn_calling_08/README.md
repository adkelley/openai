# fn_calling_08

This example demonstrates function calling with the Responses API. It gives the
model a `get_horoscope` tool, inspects the returned tool calls, creates
`function_call_output` items locally, and then sends a second request so the
model can produce a final answer.

## Prerequisites

- Set `OPENAI_API_KEY` in your environment.

## Running

```sh
gleam run
```

The example shows the full manual loop:
- send a request with tools enabled
- collect `function_call` items from `response.output`
- execute the matching local function
- append `function_call_output` items to the next turn's input
- send a second request and print the final message text
