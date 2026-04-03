# shell_cmds_09

This example demonstrates a manual shell-tool loop with the Responses API. It
sends an initial request with the `shell` tool enabled, looks for a `pwd`
command in the returned shell call, executes the local FFI helper, then sends a
second request with the tool output attached.

## Prerequisites

- Set `OPENAI_API_KEY` in your environment.
- Run the example on a system where the bundled `ffi.erl` `pwd` helper works.

## Running

```sh
gleam run
```

The example is intentionally explicit about how shell tool calls are unpacked
and how `ShellCallOutput` items are appended to the next turn's input.
