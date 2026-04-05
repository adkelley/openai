# web_search_04

This example demonstrates the web search preview tool with the Responses API.
It sends a question, enables `WebSearchPreview`, and uses
`responses.create_with_decoder/3` to decode the returned answer text directly.

## Prerequisites

- Set `OPENAI_API_KEY` in your environment.
- Edit `prompt` in `src/web_search_04.gleam` if you want to ask a different
  question.

## Running

```sh
gleam run
```

The example demonstrates the custom decoder path for simple text extraction
from a Responses payload.
