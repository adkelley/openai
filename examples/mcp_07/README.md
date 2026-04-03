# mcp_07

This example demonstrates how to call a remote MCP server through the Responses
API. It configures the `deepwiki` server, allows two MCP tools, applies an
approval filter, and prints the first text message returned by the model.

## Prerequisites

- Set `OPENAI_API_KEY` in your environment.
- Ensure the configured MCP server at `https://mcp.deepwiki.com/mcp` is
  reachable.

## Running

```sh
gleam run
```

The example uses `mcp.default_mcp/1`, `allowed_tools/2`,
`mcp_tool_approval_filter/3`, and `responses.reasoning/2` to build the request.
