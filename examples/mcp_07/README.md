# mcp_07

An executable example that demonstrates how to call the OpenAI Responses API
from Gleam while enabling the Model Context Protocol (MCP) web search tool. It
ships as part of the `openai` SDK examples and is meant to be run directly
rather than consumed as a library.

## What it does

The `src/mcp_07.gleam` program:

1. Reads the `OPENAI_API_KEY` from the environment using `envoy`.
2. Builds a `responses` request targeted at `shared.GPT5`.
3. Enables the `deepwiki` MCP connector so the model can call a remote
   `ask_question` endpoint when it needs web search context.
4. Prints the full JSON payload that OpenAI returns, allowing you to inspect
   tool calls, citations, and streamed content.

Use this example as a starting point when integrating MCP-powered tools into
your own Gleam projects.

## Prerequisites

- Gleam 1.0+
- An OpenAI API key exported as `OPENAI_API_KEY`
- Network access to `https://api.openai.com` and the configured MCP server

## Running the example

```sh
gleam deps download   # Fetch dependencies once
gleam run             # Execute src/mcp_07.gleam
```

During a run you will see the prompt echoed to stdout followed by either a
successful response payload or the error returned by the SDK.
