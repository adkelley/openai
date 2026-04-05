# shell_cmds_09

This example demonstrates a manual shell-tool loop with the Responses API. It
sends an initial request with the `shell` tool enabled, decodes the `pwd`
command from the returned shell call, executes the local FFI helper, then sends
a second request with the tool output attached.

## Prerequisites

- Set `OPENAI_API_KEY` in your environment.
- Run the example on a system where the bundled `ffi.erl` `pwd` helper works.

## Running

```sh
gleam run
```

The example uses `responses.create_with_decoder/3` for both hops:
- hop 1 decodes only the response id and shell call metadata
- hop 2 continues with `responses.with_previous_response_id/2`
- the final answer text is decoded directly from the response payload
