# skills_12

This example demonstrates how to register a local `skills.md` file with the
Responses API by attaching it to the `shell` tool's local environment. The
example points the model at the `examples/skills_12/skills.md` weather skill,
combines it with a restricted `weather.gov` web search tool, and completes the
tool loop with custom decoders.

## Prerequisites

- Set `OPENAI_API_KEY` in your environment.
- Run the example from the `examples/skills_12` directory so the skill path `.`
  resolves to the directory that contains `skills.md`.

## Running

```sh
gleam run
```

The example builds a `shell` tool with `environment.type = "local"`, narrows
web search to `weather.gov`, decodes shell call metadata for hop 1, and then
decodes the first non-empty final answer text for hop 2.
