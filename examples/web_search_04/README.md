# web_search_04

This example demonstrates the web search preview tool with the Responses API.
It sends a question, enables `WebSearchPreview`, and prints the first output
message plus any URL citations returned by the model.

## Prerequisites

- Set `OPENAI_API_KEY` in your environment.
- Edit `prompt` in `src/web_search_04.gleam` if you want to ask a different
  question.

## Running

```sh
gleam run
```

The example uses the current client-based `responses.create/2` flow and then
folds over `message.URLCitation` annotations to print the cited sources.
