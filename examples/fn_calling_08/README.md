# fn_calling_08

This example demonstrates function calling with the Responses API. It gives the
model a `get_horoscope` tool, decodes only the returned tool calls it needs,
creates `function_call_output` items locally, and then sends a second request
so the model can produce a final answer.

## Prerequisites

- Set `OPENAI_API_KEY` in your environment.

## Running

```sh
gleam run
```

The example shows a compact two-hop loop:
- send a request with tools enabled
- decode the response id plus `function_call` items needed for hop 2
- execute the matching local function
- continue with `responses.with_previous_response_id/2`
- decode the final message text directly with `responses.create_with_decoder/3`
