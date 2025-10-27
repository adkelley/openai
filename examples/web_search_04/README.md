# web_search_04

## Overview

This example enables web search tool usage with the Responses API. It constructs
a request that prefers web search, constrains domains, and prints the full API
response so you can inspect the referenced sources.

## Prerequisites

- Set the `OPENAI_API_KEY` environment variable before running the example.
- Update the `prompt` in `src/web_search_04.gleam` to explore different topics.
- Optionally adjust the allowed domains or location filters in the request
  builder to match your needs.

## Running the example

```sh
gleam run
```

The program will:

1. Load `OPENAI_API_KEY` from the environment.
2. Build a Responses API request that enables the `web_search` tool.
3. Limit results to a whitelisted domain and provide a user location hint.
4. Execute the request and print the raw response payload.

See `src/web_search_04.gleam` for further details on the request structure and
how to adapt it for your own application.
